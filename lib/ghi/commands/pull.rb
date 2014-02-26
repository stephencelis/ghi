module GHI
  module Commands
    class Pull < Command
      SUBCOMMANDS = %w{ show fetch merge create edit close }
      SUBCOMMANDS.each do |cmd|
        autoload cmd.capitalize, "ghi/commands/pull/#{cmd}"
      end

      def execute
        handle_help_request
        parse_subcommand
      end

      # common operations of all subcommands before they start
      # their individual execution
      def subcommand_execute
        handle_help_request
        require_issue
        extract_issue
        # all options terminate after execution
        options.parse!(args)
      end

      def handle_help_request
        if args.first.match(/--?h(elp)?/)
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

      private

      def pull_uri
        "/repos/#{repo}/pulls/#{issue}"
      end

      # dirty hack - this allows us to use the same format_issue
      # method as all other issues do
      def honor_the_issue_contract(pr)
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
