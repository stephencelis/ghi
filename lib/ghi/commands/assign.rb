module GHI
  module Commands
    class Assign < Command
      #   usage: ghi assign [options] [<issueno> [[<user>/]<repo>]]
      #      or: ghi unassign <issueno> [[<user>/]<repo>]]
      #   
      #       -l, --list                       list assigned issues
      #       -d, --no-assignee                assign this issue to no one
      #       -u, --assignee <user>            assign to specified user
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi assign [options] [<issueno> [[<user>/]<repo>]]
   or: ghi unassign <issueno> [[<user>/]<repo>]]
EOF
          opts.separator ''
          opts.on '-l', '--list', 'list assigned issues' do
            assigns[:list] = true
          end
          opts.on  '-d', '--no-assignee', 'assign this issue to no one' do
            assigns[:assignee] = nil
          end
          opts.on(
            '-u', '--assignee <user>', 'assign to specified user'
          ) do |assignee|
            assigns[:assignee] = assignee
          end
          opts.separator ''
        end
      end

      def execute
        require_issue
        require_repo
        options.parse! args
      end
    end
  end
end
