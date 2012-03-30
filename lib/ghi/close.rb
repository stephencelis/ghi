module GHI
  class Close
    #   usage: ghi close [<options>] <issueno> [[<user>/]<repo>]
    #   
    #       -l, --list                       list closed issues
    #
    #   Issue modification options
    #       -m, --message <text>             close with message
    def self.options
      OptionParser.new do |opts|
        opts.banner = <<EOF
usage: ghi close [<options>] <issueno> [[<user>/]<repo>]
EOF
        opts.separator ''
        opts.on '-l', '--list', 'list closed issues'
        opts.separator ''
        opts.separator 'Issue modification options'
        opts.on '-m', '--message <text>', 'close with message'
        opts.separator ''
      end
    end

    def self.execute args
      options.parse! args.empty? ? %w(-h) : args
    end
  end
end
