require 'date'

module GHI
  module Commands
    class List < Command
      attr_accessor :reverse

      #   usage: ghi list [options] [[<user>/]<repo>]
      #
      #       -a, --all                        all of your issues on GitHub
      #       -s, --state <in>                 open or closed
      #       -L, --label <labelname>,...      by label(s)
      #       -S, --sort <by>                  created, updated, or comments
      #           --reverse                    reverse (ascending) sort order
      #           --since <date>               issues more recent than
      #
      #   Global options
      #       -f, --filter <by>                assigned, created, mentioned, or
      #                                        subscribed
      #
      #   Project options
      #       -M, --[no-]milestone [<n>]       with (specified) milestone
      #       -u, --[no-]assignee [<user>]     assigned to specified user
      #           --mine                       assigned to you
      #       -U, --mentioned [<user>]         mentioning you or specified user
      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi list [options] [[<user>/]<repo>]'
          opts.separator ''
          opts.on '-a', '--global', '--all', 'all of your issues on GitHub' do
            @repo = nil
          end
          opts.on(
            '-s', '--state <in>', %w(open closed),
            {'o'=>'open', 'c'=>'closed'}, 'open or closed'
          ) do |state|
            assigns[:state] = state
          end
          opts.on(
            '-L', '--label <labelname>,...', Array, 'by label(s)'
          ) do |labels|
            assigns[:labels] = labels.join ','
          end
          opts.on(
            '-S', '--sort <by>', %w(created updated comments),
            {'c'=>'created','u'=>'updated','m'=>'comments'},
            'created, updated, or comments'
          ) do |sort|
            assigns[:sort] = sort
          end
          opts.on '--reverse', 'reverse (ascending) sort order' do
            self.reverse = !reverse
          end
          opts.on '--since <date>', 'issues more recent than' do |date|
            begin
              assigns[:since] = DateTime.parse date # TODO: Better parsing.
            rescue ArgumentError => e
              raise OptionParser::InvalidArgument, e.message
            end
          end
          opts.separator ''
          opts.separator 'Global options'
          opts.on(
            '-f', '--filter <by>',
            filters = %w(assigned created mentioned subscribed),
            Hash[filters.map { |f| [f[0, 1], f] }],
            'assigned, created, mentioned, or', 'subscribed'
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
        end

        if reverse
          assigns[:sort] ||= 'created'
          assigns[:direction] = 'asc'
        end

        extract_repo args.pop
        print format_issues_header
        issues = throb(0, format_state(assigns[:state], '#')) {
          api.get uri, assigns
        }
        puts format_issues(issues, repo.nil?)
      rescue Client::Error => e
        if e.response.is_a?(Net::HTTPNotFound) && Authorization.username.nil?
          raise Authorization::Required, 'Authorization required.'
        end

        abort e.message
      end

      private

      def uri
        repo ? "/repos/#{repo}/issues" : '/issues'
      end

      def fallback
        OptionParser.new do |opts|
          opts.on('-c', '--closed') { assigns[:state] = 'closed' }
        end
      end
    end
  end
end
