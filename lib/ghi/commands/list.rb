require 'curses'
require 'date'

module GHI
  module Commands
    class List < Command
      attr_accessor :reverse
      attr_accessor :quiet

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
            assigns[:labels] = labels.join ','
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
          opts.on '-v', '--verbose' do
            self.verbose = true
          end
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
        begin
          options.parse! args
        rescue OptionParser::InvalidOption => e
          fallback.parse! e.args
          retry
        end

        if reverse
          assigns[:sort] ||= 'created'
          assigns[:direction] = 'asc'
        end

        unless quiet
          print format_issues_header
          print "\n" unless STDOUT.tty?
        end
        res = throb(
          0, format_state(assigns[:state], quiet ? CURSOR[:up][1] : '#')
        ) { api.get uri, assigns }
        loop do
          issues = res.body
          if verbose
            puts issues.map { |i| format_issue i }
          else
            puts format_issues(issues, repo.nil?)
          end
          break unless res.next_page
          page?
          res = throb { api.get res.next_page }
        end
      end

      private

      def uri
        repo ? "/repos/#{repo}/issues" : '/issues'
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
