module GHI
  module Commands
    class Show < Command
      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi show <issueno> [[<user>/]<repo>]'
          opts.separator ''
        end
      end

      def execute
        require_issue
        require_repo

        i = api.get("/repos/#{repo}/issues/#{issue}")
        puts format_issue(i)
      end
    end
  end
end
