module GHI
  module Commands
    class Config < Command
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi config [options]
EOF
          opts.separator ''
          opts.on '--auth [<username>:<password>]' do |credentials|
            username, password = credentials.split ':' if credentials
            username ||= ENV['GITHUB_USER']
            password ||= ENV['GITHUB_PASSWORD']

            api.post 
            p credentials
          end
          opts.separator ''
        end
      end

      def execute
        options.parse! args.empty? ? %w(-h) : args
      end
    end
  end
end
