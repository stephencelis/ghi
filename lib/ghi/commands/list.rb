require 'date'

module GHI
  module Commands
    class List < Command
      attr_accessor :web
      attr_accessor :reverse
      attr_accessor :quiet
      attr_accessor :exclude_pull_requests

      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi list [options]'
          opts.separator ''
          opts.on '-a', '--global', '--all', 'all of your issues on GitHub' do
            @repo = nil
          end
          opts.on(
            '-s', '--state <in>', %w(open closed),
            {'o'=>'open', 'c'=>'closed'}, "'open' or 'closed'"
          ) do |state|
            assigns[:state] = state
          end
          opts.on(
            '-L', '--label <labelname>...', Array, 'by label(s)'
          ) do |labels|
            (assigns[:labels] ||= []).concat labels
          end
          opts.on(
            '-S', '--sort <by>', %w(created updated comments),
            {'c'=>'created','u'=>'updated','m'=>'comments'},
            "'created', 'updated', or 'comments'"
          ) do |sort|
            assigns[:sort] = sort
          end
          opts.on '--reverse', 'reverse (ascending) sort order' do
            self.reverse = !reverse
          end
          opts.on('-p', '--no-pulls','exclude pull requests') { self.exclude_pull_requests = true }
          opts.on(
            '--since <date>', 'issues more recent than',
            "e.g., '2011-04-30'"
          ) do |date|
            begin
              assigns[:since] = DateTime.parse date # TODO: Better parsing.
            rescue ArgumentError => e
              raise OptionParser::InvalidArgument, e.message
            end
          end
          opts.on('-v', '--verbose') { self.verbose = true }
          opts.on('-w', '--web') { self.web = true }
          opts.separator ''
          opts.separator 'Global options'
          opts.on(
            '-f', '--filter <by>',
            filters = %w(assigned created mentioned subscribed),
            Hash[filters.map { |f| [f[0, 1], f] }],
            "'assigned', 'created', 'mentioned', or", "'subscribed'"
          ) do |filter|
            assigns[:filter] = filter
          end
          opts.separator ''
          opts.separator 'Project options'
          opts.on(
            '-M', '--[no-]milestone [<n>]', Integer,
            'with (specified) milestone'
          ) do |milestone|
            assigns[:milestone] = any_or_none_or milestone
          end
          opts.on(
            '-u', '--[no-]assignee [<user>]', 'assigned to specified user'
          ) do |assignee|
            assignee = assignee.sub /^@/, '' if assignee
            assigns[:assignee] = any_or_none_or assignee
          end
          opts.on '--mine', 'assigned to you' do
            assigns[:assignee] = Authorization.username
          end
          opts.on(
            '-U', '--mentioned [<user>]', 'mentioning you or specified user'
          ) do |mentioned|
            assigns[:mentioned] = mentioned || Authorization.username
          end
          opts.separator ''
        end
      end

      def execute
        if index = args.index { |arg| /^@/ === arg }
          assigns[:assignee] = args.delete_at(index)[1..-1]
        end

        begin
          options.parse! args
        rescue OptionParser::InvalidOption => e
          fallback.parse! e.args
          retry
        end
        assigns[:labels] = assigns[:labels].join ',' if assigns[:labels]
        if reverse
          assigns[:sort] ||= 'created'
          assigns[:direction] = 'asc'
        end
        if web
          Web.new(repo || 'dashboard').open 'issues', assigns
        else
          assigns[:per_page] = 100
          unless quiet
            print header = format_issues_header
            print "\n" unless paginate?
          end
          res = throb(
            0, format_state(assigns[:state], quiet ? CURSOR[:up][1] : '#')
          ) { api.get uri, assigns }
          print "\r#{CURSOR[:up][1]}" if header && paginate?
          page header do
            issues = res.body
            if exclude_pull_requests
              issues = issues.reject {|i| i["pull_request"].any? {|k,v| !v.nil? } }
            end
            if verbose
              puts issues.map { |i| format_issue i }
            else
              puts format_issues(issues, repo.nil?)
            end
            break unless res.next_page
            res = throb { api.get res.next_page }
          end
        end
      rescue Client::Error => e
        if e.response.code == '422'
          e.errors.any? { |err|
            err['code'] == 'missing' && err['field'] == 'milestone'
          } and abort 'No such milestone.'
        end

        raise
      end

      private

      def uri
        (repo ? "/repos/#{repo}" : '') << '/issues'
      end

      def fallback
        OptionParser.new do |opts|
          opts.on('-c', '--closed') { assigns[:state] = 'closed' }
          opts.on('-q', '--quiet')  { self.quiet = true }
        end
      end
    end
  end
end
