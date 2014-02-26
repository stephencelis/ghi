module GHI
  module Commands
    class Pull::Show < Pull
      def options
        OptionParser.new do |opts|
          opts.banner = "show - displays details of a pull request"
          opts.on('-c', '--commits', 'show associated commits') { commits; abort }
          opts.on('-d', '--diff', 'show diff') { diff; abort }
          opts.on('-p', '--patch', 'show patch') { patch; abort}
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
        diff = throb { get_html diff_uri}
        page do
          puts diff
        end
      end

      def patch
        patch = throb { get_html patch_uri }
        page do
          puts patch
        end
      end

      def diff_uri
        "pull/#{issue}.diff"
      end

      def patch_uri
        "pull/#{issue}.patch"
      end

      def commits_uri
        "#{pull_uri}/commits"
      end
    end
  end
end
