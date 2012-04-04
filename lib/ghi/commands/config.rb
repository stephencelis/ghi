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
          opts.on '--auth [<username>:<password>]' do |credentials|
            self.action = 'auth'
            username, password = credentials.split ':', 2 if credentials
            assigns[:username] = username
            assigns[:password] = password
          end
          opts.separator ''
        end
      end

      def execute
        global = true
        options.parse! args.empty? ? %w(-h) : args

        if self.action == 'auth'
          Authorization.authorize!(
            assigns[:username], assigns[:password], assigns[:local]
          )
        end
      end
    end
  end
end
