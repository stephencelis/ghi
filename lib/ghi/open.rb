module GHI
  class Open < Command
    #   usage: ghi open [options] [[<user>/]<repo>]
    #      or: ghi reopen [options] <issueno> [[<user>/]<repo>]
    #   
    #       -l, --list                       list open tickets
    #   
    #   Issue modification options
    #       -m, --message <text>             describe issue
    #       -u, --[no-]assign <user>         assign to specified user
    #       -M, --milestone <n>              associate with milestone
    #       -L, --label <labelname>...       associate with label(s)
    def self.options
      OptionParser.new do |opts|
        opts.banner = <<EOF
usage: ghi open [options] [[<user>/]<repo>]
   or: ghi reopen [options] <issueno> [[<user>/]<repo>]
EOF
        opts.separator ''
        opts.on('-l', '--list', 'list open tickets')
        opts.separator ''
        opts.separator 'Issue modification options'
        opts.on '-m', '--message <text>', 'describe issue'
        opts.on '-u', '--[no-]assign <user>', 'assign to specified user'
        opts.on '-M', '--milestone <n>', 'associate with milestone'
        opts.on(
          '-L', '--label <labelname>...', Array, 'associate with label(s)'
        )
        opts.separator ''
      end
    end

    def self.execute args
      options.parse! args.empty? ? %w(-h) : args
    end
  end
end
