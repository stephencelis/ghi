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

        res = throb { api.get show_uri }
        pr  = res.body
        honor_the_issue_contract(pr)

        page do
          puts format_issue(pr) { format_pull_info(pr) }
          output_issue_comments(pr['comments'])
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
    end
  end
end
