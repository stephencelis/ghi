module GHI
  module Commands
    class Config < Command
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi config [options]
EOF
          opts.separator ''
          opts.on '--local', 'set for local repo only' do
            assigns[:local] = true
          end
          opts.on '--auth [<username>]' do |username|
            self.action = 'auth'
            assigns[:username] = username || Authorization.username
          end
          opts.separator ''
        end
      end

      def execute
        global = true
        options.parse! args.empty? ? %w(-h) : args

        if action == 'auth'
          assigns[:password] = Authorization.password || get_password
          Authorization.authorize!(
            assigns[:username], assigns[:password], assigns[:local]
          )
        end
      end

      private

      def get_password
        print "Enter #{assigns[:username]}'s GitHub password (never stored): "
        current_tty = `stty -g`
        system 'stty raw -echo -icanon isig' if $?.success?
        input = ''
        while char = $stdin.getbyte and not (char == 13 or char == 10)
          if char == 127 or char == 8
            input[-1, 1] = '' unless input.empty?
          else
            input << char.chr
          end
        end
        input
      rescue Interrupt
        print '^C'
      ensure
        system "stty #{current_tty}" unless current_tty.empty?
      end
    end
  end
end
