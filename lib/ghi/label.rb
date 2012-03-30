module GHI
  class Label
    def self.options
      OptionParser.new do |opts|
        opts.banner = <<EOF
usage: ghi label <labelname> [-c <color>] [-r <newname>]
   or: ghi label -d <labelname>
   or: ghi label -l
   or: ghi label <issueno> <labelname>...
EOF
        opts.separator ''
        opts.on('-l', '--list', 'list label names')
        opts.on('-d', '--delete <labelname>', 'delete labels')
        opts.separator ''
        opts.separator 'Label modification options'
        opts.on('-c', '--color <color>', '6 character hex code')
        opts.on('-r', '--rename <labelname>', 'new label name')
        opts.separator ''
      end
    end

    def self.execute args
      options.parse! args.empty? ? ['-h'] : args
    end
  end
end
