module GHI
  module Commands
    class MissingArgument < RuntimeError
    end

    class Command
      include Formatting

      class << self
        attr_accessor :detected_repo

        def execute args
          command = new args
          if i = args.index('--')
            command.repo = args.slice!(i, args.length)[1] # Raise if too many?
          end
          command.execute
        end
      end

      attr_reader :args
      attr_writer :issue
      attr_accessor :action
      attr_accessor :verbose

      def initialize args = []
        @args = args.map! { |a| a.dup }
      end

      def assigns
        @assigns ||= {}
      end

      def api
        @api ||= Client.new
      end

      def repo
        return @repo if defined? @repo
        @repo = GHI.config('ghi.repo', :flags => '--local') || detect_repo
        if @repo && !@repo.include?('/')
          @repo = [Authorization.username, @repo].join '/'
        end
        @repo
      end
      alias extract_repo repo

      def repo= repo
        @repo = repo.dup
        unless @repo.include? '/'
          @repo.insert 0, "#{Authorization.username}/"
        end
        @repo
      end

      private

      def require_repo
        return true if repo
        warn 'Not a GitHub repo.'
        warn ''
        abort options.to_s
      end

      def detect_repo
        remote   = upstream
        remote ||= origin
        remote ||= remotes.find { |r| r[:user]   == Authorization.username }
        Command.detected_repo = true and remote[:repo] if remote
      end

      def remotes
        return @remotes if defined? @remotes
        @remotes = `git config --get-regexp remote\..+\.url`.split "\n"
        github_host = GHI.config('github.host') || 'github.com'
        @remotes.reject! { |r| !r.include? github_host}
        @remotes.map! { |r|
          remote, user, repo = r.scan(
            %r{remote\.([^\.]+)\.url .*?([^:/]+)/([^/\s]+?)(?:\.git)?$}
          ).flatten
          { :remote => remote, :user => user, :repo => "#{user}/#{repo}" }
        }
        @remotes
      end

      def issue
        return @issue if defined? @issue
        if index = args.index { |arg| /^\d+$/ === arg }
          @issue = args.delete_at index
        else
          @issue = current_branch[/^\d+/];
          warn "(Inferring issue from branch prefix: ##@issue)" if @issue
        end
        @issue
      end
      alias extract_issue     issue
      alias milestone         issue
      alias extract_milestone issue

      def current_branch
        `git symbolic-ref --short HEAD 2>/dev/null`.chomp
      end

      def origin
        remotes.find { |r| r[:remote] == 'origin' }
      end

      def upstream
        remotes.find { |r| r[:remote] == 'upstream' }
      end

      def require_issue
        raise MissingArgument, 'Issue required.' unless issue
      end

      def require_milestone
        raise MissingArgument, 'Milestone required.' unless milestone
      end

      # Handles, e.g. `--[no-]milestone [<n>]`.
      def any_or_none_or input
        input ? input : { nil => '*', false => 'none' }[input]
      end

      def sort_by_creation(arr)
        arr.sort_by { |el| el['created_at'] }
      end

      def output_issue_comments(n)
        return if n.zero?
        puts "#{n} comment#{'s' unless n == 1}:\n\n"
        Comment.execute %W(-l #{issue} -- #{repo})
      end

      def issue_uri
        "/repos/#{repo}/issues/#{issue}"
      end

      def pull_uri
        "/repos/#{repo}/pulls/#{issue}"
      end

      # Takes code blocks that will execute multithreaded. Returns an
      # array of each threads return value.
      # Code blocks need to handle their errors themselves!
      def do_threaded(*blks)
        threads = blks.map { |blk| Thread.new { blk.call } }
        threads.map { |t| t.join; t.value }
      end
    end
  end
end
