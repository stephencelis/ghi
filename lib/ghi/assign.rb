module GHI
  class Assign < Command
    #   usage: ghi assign [<options>] [<issueno> [<[user/]repo>]]
    #      or: ghi unassign <issueno> [<[user/]repo>]]
    #   
    #       -l, --list                       list assigned issues
    #       -d, --no-assignee                assign this issue to no one
    #       -u, --assignee <user>            assign to specified user
    def self.options
      OptionParser.new do |opts|
        opts.banner = <<EOF
usage: ghi assign [<options>] <issueno>
   or: ghi unassign <issueno>
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

    def self.execute args
      options.parse! args.empty? ? %w(-h) : args

      if args.empty? && assigns.key?(:assignee)
        warn "You must specify an issue number.\n"
        abort options.to_s
      end
    end
  end
end
