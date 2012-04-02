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
        options.parse! args

        if list?
          require_repo
          List.new(['-sc', repo]).execute
        else
          require_issue
          require_repo
          Edit.new(['-sc', issue, repo]).execute
          puts 'Closed.'
        end
      end

      private

      def list?
        assigns[:command] == List
      end
    end
  end
end
