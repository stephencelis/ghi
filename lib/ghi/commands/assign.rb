module GHI
  module Commands
    class Assign < Command
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi assign [options] [<issueno>]
   or: ghi assign <issueno> <user>
   or: ghi unassign <issueno>
EOF
          opts.separator ''
          opts.on(
            '-u', '--assignee <user>', 'assign to specified user'
          ) do |assignee|
            assigns[:assignee] = assignee
          end
          opts.on '-d', '--no-assignee', 'unassign this issue' do
            assigns[:assignee] = nil
          end
          opts.on '-l', '--list', 'list assigned issues' do
            self.action = 'list'
          end
          opts.separator ''
        end
      end

      def execute
        self.action = 'edit'
        assigns[:args] = []

        require_repo
        extract_issue
        options.parse! args

        unless assigns.key? :assignee
          assigns[:assignee] = args.pop || Authorization.username
        end
        if assigns.key? :assignee
          assigns[:args].concat(
            assigns[:assignee] ? %W(-u #{assigns[:assignee]}) : %w(--no-assign)
          )
        end
        assigns[:args] << issue if issue
        assigns[:args].concat %W(-- #{repo})

        case action
          when 'list' then List.execute assigns[:args]
          when 'edit' then Edit.execute assigns[:args]
        end
      end
    end
  end
end
