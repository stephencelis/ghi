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
        i = throb { api.get "/repos/#{repo}/issues/#{issue}" }.body
        puts format_issue(i)
        page? 'Load comments?'
        Comment.execute %W(-l #{issue} -- #{repo})
      end
    end
  end
end
