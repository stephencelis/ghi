module GHI
  module Commands
    class Comment < Command
      #   usage: ghi comment [options] <issueno> [[<user>/]<repo>]
      #   
      #       -l, --list                       list comments
      #       -v, --verbose                    list events, too
      #           --amend                      amend previous comment
      #       -D, --delete                     delete previous comment
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi comment [options] <issueno> [[<user>/]<repo>]
EOF
          opts.separator ''
          opts.on '-l', '--list', 'list comments'
          opts.on '-v', '--verbose', 'list events, too'
          opts.separator ''
          opts.separator 'Comment modification options'
          opts.on '-m', '--message <text>', 'comment body'
          opts.on '--amend', 'amend previous comment'
          opts.on '-D', '--delete', 'delete previous comment'
          opts.separator ''
        end
      end

      def execute
        options.parse! args.empty? ? %w(-h) : args
      end
    end
  end
end
