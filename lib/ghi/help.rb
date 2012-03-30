module GHI
  class Help < Command
    def self.options
      OptionParser.new do |opts|
        opts.banner = 'usage: ghi help [--all] [--man|--web] <command>'
        opts.separator ''
        opts.on('-a', '--all', 'print all available commands') { all }
        opts.on('-m', '--man', 'show man page')                { man command }
        opts.on('-w', '--web', 'show manual in web browser')   { web command }
        opts.separator ''
      end
    end

    def self.execute args, message = nil
      command = args.shift if args.first !~ /^-/

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

See 'ghi help <command>' for more information on a specific command.
EOF
        exit
      end

      options.parse! args
    end

    def self.all
      raise 'TODO'
    end

    def self.man command
      command = ['ghi', command].compact.join '-'
      exec "man #{command}"
    end

    def self.web command
      raise 'TODO'
    end
  end
end
