module GHI
  module Commands
    class Command
      include Formatting

      def self.execute args
        new(args).execute
      end

      attr_reader :args
      attr_writer :issue
      def initialize args
        @args = args.map { |a| a.dup }
      end

      private

      def assigns
        @assigns ||= {}
      end

      def api
        @api ||= Client.new
      end

      def repo
        return @repo if defined? @repo

        if @repo = args.pop
          @repo.prepend "#{Authorization.username}/" unless @repo.include? '/'
        else
          remotes = `git config --get-regexp remote\..+\.url`.split "\n"
          if remote = remotes.find { |r| r.include? 'github.com' }
            @repo = remote.scan(%r{([^:/]+)/([^/\s]+?)(?:\.git)?$}).join '/'
          end
        end

        @repo
      end
      alias extract_repo repo

      def require_repo
        return true if repo
        warn 'Not a GitHub repo.'
        abort options.to_s
      end

      def issue
        return @issue if defined? @issue
        index = args.index { |arg| /^\d+$/ === arg }
        @issue = (args.delete_at index if index)
      end
      alias extract_issue issue

      def require_issue
        return true if issue
        warn 'Specify an issue number.'
        abort options.to_s
      end

      # Handles, e.g. `--[no-]milestone [<n>]`.
      def any_or_none_or input
        input ? input : { nil => '*', false => 'none' }[input]
      end
    end
  end
end
