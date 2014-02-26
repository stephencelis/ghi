module GHI
  module Commands
    class Pull::Show < Pull
      def options
        OptionParser.new do |opts|
          opts.banner = "show - displays details of a pull request"
          opts.on('-c', '--commits', 'show associated commits') { commits; abort }
          opts.on('-d', '--diff', 'show diff') { diff; abort }
        end
      end

      def execute
        require_issue
        extract_issue
        # all options terminate after execution
        options.parse!(args)

        res = throb { api.get pull_uri }
        pr  = res.body
        honor_the_issue_contract(pr)

        page do
          puts format_issue(pr) { format_pull_info(pr) }
          output_issue_comments(pr['comments'])
          break
        end
      end

      def commits
        commits = throb { api.get commits_uri }.body
        page do
          puts format_commits(commits)
          break
        end
      end

      def diff
        # this is actually a html page - easily parsed but our api
        # wants JSON.
      end


      def diff_uri
        "#{repo}/pulls/#{issue}.diff"
      end

      def commits_uri
        "#{pull_uri}/commits"
      end
    end
  end
end
