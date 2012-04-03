module GHI
  module Commands
    class Close < Command
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi close [options] <issueno>
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
        require_repo

        if list?
          List.execute %W(-sc -- #{repo})
        else
          require_issue
          Edit.execute %W(-sc #{issue} -- #{repo})
          puts 'Closed.'
          if assigns[:comment]
            Comment.execute %W(#{issue} -m #{assigns[:comment]} -- #{repo})
          end
        end
      end

      private

      def list?
        assigns[:command] == List
      end
    end
  end
end
