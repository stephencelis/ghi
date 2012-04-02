module GHI
  module Commands
    class Close < Command
      #   usage: ghi close [options] <issueno> [[<user>/]<repo>]
      #   
      #       -l, --list                       list closed issues
      #
      #   Issue modification options
      #       -m, --message <text>             close with message
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi close [options] <issueno> [[<user>/]<repo>]
EOF
          opts.separator ''
          opts.on '-l', '--list', 'list closed issues' do
            assigns[:command] = List
            assigns[:args] = %w(--state closed)
          end
          opts.separator ''
          opts.separator 'Issue modification options'
          opts.on '-m', '--message <text>', 'close with message' do |text|
            assigns[:comment] = text
          end
          opts.separator ''
        end
      end

      def execute
        require_issue
        require_repo

        options.parse! args

        (assigns[:command] || Edit).new(['-sc', issue, repo]).execute
      end
    end
  end
end
