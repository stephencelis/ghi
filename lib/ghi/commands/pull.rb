module GHI
  module Commands
    class Pull < Command
      SUBCOMMANDS = %w{ show fetch merge create edit close }
      SUBCOMMANDS.each do |cmd|
        autoload cmd.capitalize, "ghi/commands/pull/#{cmd}"
      end

      attr_writer :pr

      def execute
        handle_help_request
        parse_subcommand
      end

      # common operations of all subcommands before they start
      # their individual execution
      def subcommand_execute(no_issue_needed = false)
        handle_help_request
        unless no_issue_needed
          require_issue
          extract_issue
        end
        options.parse!(args)
      end

      def handle_help_request
        if args.first.to_s.match(/--?h(elp)?/)
          abort help
        end
      end

      def help
        <<EOF
Usage: ghi pull <subcommand> <pull_request_no> [options]

----- Subcommands -----

#{SUBCOMMANDS.map { |cmd| to_const(cmd).help }.compact.join("\n")}
EOF
      end
      # fall back to satisfy ghi's rescue operations to print a help screen
      alias options help

      def parse_subcommand
        subcommand = args.shift
        if SUBCOMMANDS.include?(subcommand)
          to_const(subcommand).new(args).execute
        else
          abort "Invalid Syntax\n#{help}"
        end
      end

      def pr
        @pr ||= throb { api.get pull_uri }.body
      end

      def show_pull_request
        honor_the_issue_contract
        page do
          puts format_issue(pr) { format_pull_info(pr) }
          output_issue_comments(pr['comments'])
          break
        end
      end

      private

      def compare_uri
        "/repos/#{repo}/compare/#{base}...#{head}"
      end

      def head
        pr['head']['label']
      end

      def base
        pr['base']['label']
      end

      def dirty?
        !pr['mergeable'] && pr['mergeable_state'] == 'dirty'
      end

      def clean?
        pr['mergeable'] && pr['mergeable_state'] == 'clean'
      end

      def needs_rebase?
        compare_head_and_base['status'] == 'diverged'
      end

      def compare_head_and_base
        @comparison ||= api.get(compare_uri).body
      end

      # dirty hack - this allows us to use the same format_issue
      # method as all other issues do
      def honor_the_issue_contract
        pr['pull_request'] = { 'html_url' => true }
        pr['labels'] = []
      end

      def to_const(str)
        self.class.const_get(str.capitalize)
      end

      def self.help
        new([]).options.to_s
      end

      def get_html(path)
        Web.new(repo).curl path
      end
    end
  end
end
