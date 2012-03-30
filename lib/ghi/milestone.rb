module GHI
  class Milestone
    #   usage: ghi milestone [<modification options>] [<milestoneno>]
    #          [[<user>]/<repo>]
    #      or: ghi milestone -D <milestoneno> [[<user>/]<repo>]
    #      or: ghi milestone -l [-c]
    #   
    #       -l, --list                       list milestones
    #       -c, --[no-]closed                show closed milestones
    #           --sort <on>                  due_date completeness
    #                                        due_date or completeness
    #           --reverse                    reverse (ascending) sort order
    #   
    #   Milestone modification options
    #       -m, --message <text>             change milestone description
    #       -s, --state <in>                 open or closed
    #           --due <on>                   when milestone should be complete
    #       -D, --delete <milestoneno>       delete milestone
    def self.options
      OptionParser.new do |opts|
        opts.banner = <<EOF
usage: ghi milestone [<modification options>] [<milestoneno>] [[<user>]/<repo>]
   or: ghi milestone -D <milestoneno> [[<user>/]<repo>]
   or: ghi milestone -l [-c]
EOF
        opts.separator ''
        opts.on '-l', '--list', 'list milestones'
        opts.on '-c', '--[no-]closed', 'show closed milestones'
        opts.on(
          '--sort <on>', %(due_date completeness),
          {'d'=>'due_date','due'=>'due_date','c'=>'completeness'},
          'due_date or completeness'
        )
        opts.on '--reverse', 'reverse (ascending) sort order'
        opts.separator ''
        opts.separator 'Milestone modification options'
        opts.on '-m', '--message <text>', 'change milestone description'
        opts.on(
          '-s', '--state <in>', %w(open closed), {'o'=>'open','c'=>'closed'},
          'open or closed'
        ) do |state|
          assigns[:state] = state
        end
        opts.on '--due <on>', 'when milestone should be complete'
        opts.on '-D', '--delete <milestoneno>', 'delete milestone'
        opts.separator ''
      end
    end

    def self.execute args
      options.parse! args.empty? ? ['-h'] : args
    end
  end
end
