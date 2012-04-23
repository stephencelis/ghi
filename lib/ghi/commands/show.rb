module GHI
  module Commands
    class Show < Command
      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi show <issueno>'
          opts.separator ''
        end
      end

      def execute
        require_issue
        require_repo
        i = throb { api.get "/repos/#{repo}/issues/#{issue}" }.body
        page do
          puts format_issue(i)
          n = i['comments']
          if n > 0
            puts "#{n} comment#{'s' unless n == 1}:\n\n"
            Comment.execute %W(-l #{issue} -- #{repo})
          end
          break
        end
      end
    end
  end
end
