require 'date'

module GHI
  module Commands
    class List < Command
      attr_accessor :web
      attr_accessor :reverse
      attr_accessor :quiet
      attr_accessor :exclude_pull_requests
      attr_accessor :pull_requests_only

      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi list [options]'
          opts.separator ''

          extract_globality(opts)
          extract_state(opts)
          extract_label_inclusion(opts)
          extract_label_exclusion(opts)
          extract_sorting(opts)
          extract_pull_request(opts)
          extract_dating(opts)
          extract_verbosity(opts)
          extract_web(opts)

          add_section_header(opts, 'Global')

          opts.on(
            '-f', '--filter <by>',
            filters = %w[all assigned created mentioned subscribed],
            Hash[filters.map { |f| [f[0, 1], f] }],
            filters.map { |f| "'#{f}'" }.join(', ')
          ) do |filter|
            assigns[:filter] = filter
          end

          add_section_header(opts, 'Project')

          opts.on(
            '-M', '--[no-]milestone [<n>]', Integer,
            'with (specified) milestone'
          ) do |milestone|
            assigns[:milestone] = any_or_none_or milestone
          end
          extract_assignee(opts)
          extract_assigment_to_you(opts)
          extract_creator(opts)
          extract_mentioned(opts)
          opts.separator ''
        end
      end

      def execute
        if index = args.index { |arg| /^@/ === arg }
          assigns[:assignee] = args.delete_at(index)[1..-1]
        end

        begin
          options.parse! args
          @repo ||= ARGV[0] if ARGV.one?
        rescue OptionParser::InvalidOption => e
          fallback.parse! e.args
          retry
        end
        assigns[:labels] = assigns[:labels].join ',' if assigns[:labels]
        if assigns[:exclude_labels]
          assigns[:exclude_labels] = assigns[:exclude_labels].join ','
        end
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

            if exclude_pull_requests || pull_requests_only
              prs, issues = issues.partition { |i| i['pull_request'].values.any? }
              issues = prs if pull_requests_only
            end

            issues = issues_without_excluded_labels(issues, assigns[:exclude_labels])

            put_issues(issues)

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

      def extract_globality(opts)
        opts.on '-a', '--global', '--all', 'all of your issues on GitHub' do
          assigns[:filter] = 'all'
          @repo = nil
        end
      end

      def extract_state(opts)
        opts.on(
          '-s', '--state <in>', %w(open closed),
          {'o'=>'open', 'c'=>'closed'}, "'open' or 'closed'"
        ) do |state|
          assigns[:state] = state
        end
      end

      def extract_label_inclusion(opts)
        opts.on(
          '-L', '--label <labelname>...', Array, 'by label(s)'
        ) do |labels|
          (assigns[:labels] ||= []).concat labels
        end
      end

      def extract_label_exclusion(opts)
        opts.on(
          '-N', '--not-label <labelname>...', Array, 'exclude with label(s)'
        ) do |labels|
          (assigns[:exclude_labels] ||= []).concat labels
        end
      end

      def extract_sorting(opts)
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
      end

      def extract_pull_request(opts)
        opts.on('-p', '--pulls','list only pull requests') { self.pull_requests_only = true }
        opts.on('-P', '--no-pulls','exclude pull requests') { self.exclude_pull_requests = true }
      end

      def extract_dating(opts)
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
      end

      def extract_verbosity(opts)
        opts.on('-v', '--verbose') { self.verbose = true }
      end

      def extract_web(opts)
        opts.on('-w', '--web') { self.web = true }
      end

      def extract_assignee(opts)
        opts.on(
          '-u', '--[no-]assignee [<user>]', 'assigned to specified user'
        ) do |assignee|
          assignee = assignee.sub /^@/, '' if assignee
          assigns[:assignee] = any_or_none_or assignee
        end
      end

      def extract_assigment_to_you(opts)
        opts.on '--mine', 'assigned to you' do
          assigns[:filter] = 'assigned'
          assigns[:assignee] = Authorization.username
        end
      end

      def extract_creator(opts)
        opts.on(
          '--creator [<user>]', 'created by you or specified user'
        ) do |creator|
          creator = creator.sub /^@/, '' if creator
          assigns[:creator] = creator || Authorization.username
        end
      end

      def extract_mentioned(opts)
        opts.on(
          '-U', '--mentioned [<user>]', 'mentioning you or specified user'
        ) do |mentioned|
          assigns[:mentioned] = mentioned || Authorization.username
        end
      end

      def issues_without_excluded_labels(issues, exclusions)
        return issues unless exclusions
        issues.reject  do |i|
          i["labels"].any? do |label|
            exclusions.include? label["name"]
          end
        end
      end

      def add_section_header(opts, name)
        opts.separator ''
        opts.separator "#{name} options"
      end

      def put_issues(issues)
        if verbose
          puts issues.map { |i| format_issue i }
        else
          puts format_issues(issues, repo.nil?)
        end
      end
    end
  end
end
