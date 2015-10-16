module GHI
  module Commands
    class Help < Command
      def self.execute args, message = nil
        new(args).execute message
      end

      attr_accessor :command

      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi help [--all] [--man|--web] <command>'
          opts.separator ''
          opts.on('-a', '--all', 'print all available commands') { all }
          opts.on('-m', '--man', 'show man page')                { man }
          opts.on('-w', '--web', 'show manual in web browser')   { web }
          opts.separator ''
        end
      end

      def execute message = nil
        self.command = args.shift if args.first !~ /^-/

        if command.nil? && args.empty?
          puts message if message
          puts <<EOF

The most commonly used ghi commands are:
   list        List your issues (or a repository's)
   show        Show an issue's details
   open        Open (or reopen) an issue
   close       Close an issue
   edit        Modify an existing issue
   comment     Leave a comment on an issue
   label       Create, list, modify, or delete labels
   assign      Assign an issue to yourself (or someone else)
   milestone   Manage project milestones
   status      Determine whether or not issues are enabled for this repo

See 'ghi help <command>' for more information on a specific command.
EOF
          exit
        end

        options.parse! args.empty? ? %w(-m) : args
      end

      def all
        raise 'TODO'
      end

      def man
        GHI.execute [command, '-h']
        # TODO:
        # exec "man #{['ghi', command].compact.join '-'}"
      end

      def web
        raise 'TODO'
      end
    end
  end
end
