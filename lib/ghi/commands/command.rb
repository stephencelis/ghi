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

      def initialize args
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
        warn <<-WARNING
Current directory is not a GitHub repository. Please retry this command from a
GitHub repository or by appending your command with the user/repo:

    #{GHI.current_command} -- [<user>/]<repo>

        WARNING
        abort options.to_s
      end

      def require_repo_name
        require_repo
        repo_array = repo.partition "/"
        if repo_array.length >= 2
          repo_name = repo_array[2]
        else
          repo_name = nil
        end
        return repo_name
      end

      def detect_repo
        remote   = remotes.find { |r| r[:remote] == 'upstream' }
        remote ||= remotes.find { |r| r[:remote] == 'origin' }
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
          infer_issue_from_branch_prefix
        end
        @issue
      end
      alias extract_issue     issue
      alias milestone         issue
      alias extract_milestone issue

      def infer_issue_from_branch_prefix
        @issue = `git symbolic-ref --short HEAD 2>/dev/null`[/^\d+/];
        warn "(Inferring issue from branch prefix: ##@issue)" if @issue
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
    end
  end
end
