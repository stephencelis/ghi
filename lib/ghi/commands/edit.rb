module GHI
  module Commands
    class Edit < Command
      #   usage: ghi edit [options] <issueno> [[<user>]/<repo>]
      #   
      #       -m, --message <text>             change issue description
      #       -u, --[no-]assign <user>         assign to specified user
      #       -s, --state <state>              open or closed
      #       -M, --milestone <n>              associate with milestone
      #       -L, --label <labelname>...       associate with label(s)
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi edit [options] <issueno> [[<user>]/<repo>]
EOF
          opts.separator ''
          opts.on '-m', '--message <text>', 'change issue description'
          opts.on '-u', '--[no-]assign <user>', 'assign to specified user'
          opts.on(
            '-s', '--state <in>', %w(open closed),
            {'o'=>'open', 'c'=>'closed'}, 'open or closed'
          ) do |state|
            assigns[:state] = state
          end
          opts.on '-M', '--milestone <n>', 'associate with milestone'
          opts.on(
            '-L', '--label <labelname>...', Array, 'associate with label(s)'
          )
          opts.separator ''
        end
      end

      def execute args
        options.parse! args.empty? ? %w(-h) : args
      end
    end
  end
end
