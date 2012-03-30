module GHI
  class Config < Command
    def self.options
      OptionParser.new do |opts|
        opts.banner = <<EOF
usage: ghi config [options]
EOF
      end
    end

    def self.execute
      options.parse! args.empty? ? %w(-h) : args
    end
  end
end
