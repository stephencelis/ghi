module GHI
  class Open
    def self.options
      OptionParser.new do |opts|
        opts.banner = <<EOF
usage: ghi open [<title>] [-m]
   or: ghi open <issueno>
EOF
        opts.separator ''
        opts.on('-l', '--list', 'list label names')
        opts.separator ''
      end
    end

    def self.execute args
      options.parse! args.empty? ? ['-h'] : args
    end
  end
end
