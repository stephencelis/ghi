module GHI
  module Commands
    class MissingArgument < RuntimeError
    end

    class Command
      include Formatting

      def self.execute args
        command = new args
        if i = args.index('--')
          command.repo = args.slice!(i, args.length)[1] # Raise if too many?
        end
        command.execute
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
        @repo = GHI.config('ghi.repo') || detect_repo
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
        remotes = `git config --get-regexp remote\..+\.url`.split "\n"
        remotes.reject! { |r| !r.include? 'github.com'}

        remotes.map! { |r|
          remote, user, repo = r.scan(
            %r{remote\.([^\.]+)\.url .*?([^:/]+)/([^/\s]+?)(?:\.git)?$}
          ).flatten
          { :remote => remote, :user => user, :repo => "#{user}/#{repo}" }
        }

        remote   = remotes.find { |r| r[:remote] == 'upstream' }
        remote ||= remotes.find { |r| r[:remote] == 'origin' }
        remote ||= remotes.find { |r| r[:user]   == Authorization.username }
        remote[:repo] if remote
      end

      def issue
        return @issue if defined? @issue
        index = args.index { |arg| /^\d+$/ === arg }
        @issue = (args.delete_at index if index)
      end
      alias extract_issue     issue
      alias milestone         issue
      alias extract_milestone issue

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
    end
  end
end
