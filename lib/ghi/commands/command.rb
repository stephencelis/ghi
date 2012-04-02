module GHI
  module Commands
    class Command
      include Formatting

      def self.execute args
        new(args).execute
      end

      attr_reader :args
      attr_writer :issue
      attr_accessor :action
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

      def repo repo = nil
        return @repo if repo.nil? && defined? @repo

        if repo
          @repo = repo
        elsif %r{/} === args.last
          @repo = args.pop
        else
          remotes = `git config --get-regexp remote\..+\.url`.split "\n"
          if remote = remotes.find { |r| r.include? 'github.com' }
            @repo = remote.scan(%r{([^:/]+)/([^/\s]+?)(?:\.git)?$}).join '/'
          else
            @repo = args.pop
          end
        end

        if @repo && !@repo.include?('/')
          @repo.insert 0, "#{Authorization.username}/"
        end

        @repo
      end
      alias extract_repo repo

      def require_repo
        return true if repo
        warn 'Not a GitHub repo.'
        warn ''
        abort options.to_s
      end

      def issue
        return @issue if defined? @issue
        index = args.index { |arg| /^\d+$/ === arg }
        @issue = (args.delete_at index if index)
      end
      alias extract_issue     issue
      alias milestone         issue
      alias extract_milestone issue

      def require_issue type = 'issue'
        return true if issue
        warn "You must specify an #{type} number."
        warn ''
        abort options.to_s
      end

      def require_milestone
        require_issue 'milestone'
      end

      # Handles, e.g. `--[no-]milestone [<n>]`.
      def any_or_none_or input
        input ? input : { nil => '*', false => 'none' }[input]
      end
    end
  end
end
