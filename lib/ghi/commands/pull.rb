module GHI
  module Commands
    class Pull < Command
      def options
      end

      def execute
        parse_subcommand
      end

      SUBCOMMANDS = %w{ show create edit fetch close merge }
      def parse_subcommand
        subcommand = args.shift
        if SUBCOMMANDS.include?(subcommand)
          send subcommand
        end
      end

      def show
        require_issue
        extract_issue
        # all options terminate after execution
        show_options.parse!(args)

        res = throb { api.get show_uri }
        pr  = res.body
        honor_the_issue_contract(pr)

        page do
          puts format_issue(pr) { format_pull_info(pr) }
          output_issue_comments(pr['comments'])
          break
        end
      end

      def show_options
        OptionParser.new do |opts|
          opts.banner = "show"
          opts.separator ''
          opts.on('-c', '--commits', 'show associated commits') { show_commits; abort }
          opts.on('-d', '--diff', 'show diff') { show_diff; abort }
        end
      end

      def show_commits
        commits = throb { api.get commits_uri }.body
        page do
          puts format_commits(commits)
          break
        end
      end

      # dirty hack - this allows us to use the same format_issue
      # method as all other issues do
      def honor_the_issue_contract(pr)
        pr['pull_request'] = { 'html_url' => true }
        pr['labels'] = []
      end

      private

      def show_uri
        "/repos/#{repo}/pulls/#{issue}"
      end

      def diff_uri
        "#{repo}/pulls/#{issue}.diff"
      end

      def commits_uri
        "#{show_uri}/commits"
      end
    end
  end
end
