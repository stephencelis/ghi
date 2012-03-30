module GHI
  class Label
    #   usage: ghi label <labelname> [-c <color>] [-r <newname>]
    #          [[<user>/]<repo>]
    #      or: ghi label -D <labelname> [[<user>/]<repo>]
    #      or: ghi label <issueno> [-a] [-d] [-f] <labelname>...
    #          [[<user>/]<repo>]
    #      or: ghi label -l [[<user>/]<repo>]
    #   
    #       -l, --list                       list label names
    #       -D, --delete <labelname>         delete labels
    #   
    #   Label modification options
    #       -c, --color <color>              6 character hex code
    #       -r, --rename <labelname>         new label name
    #
    #   Issue modification options
    #       -a, --add                        add label to issue
    #       -d, --delete                     remove label from issue
    #       -f, --force                      replace existing labels
    def self.options
      OptionParser.new do |opts|
        opts.banner = <<EOF
usage: ghi label <labelname> [-c <color>] [-r <newname>] [[<user>/]<repo>]
   or: ghi label -D <labelname>... [[<user>/]<repo>]
   or: ghi label <issueno> [-a] [-d] [-f] <labelname>... [[<user>/]<repo>]
   or: ghi label -l [[<user>/]<repo>]
EOF
        opts.separator ''
        opts.on('-l', '--list', 'list label names')
        opts.on('-D', '--delete <labelname>', 'delete labels')
        opts.separator ''
        opts.separator 'Label modification options'
        opts.on('-c', '--color <color>', '6 character hex code')
        opts.on('-r', '--rename <labelname>', 'new label name')
        opts.separator ''
      end
    end

    def self.execute args
      options.parse! args.empty? ? %w(-h) : args
    end
  end
end
