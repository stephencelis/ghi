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
          opts.on(
            '-m', '--message <text>', 'change issue description'
          ) do |text|
            assigns[:title] = text
          end
          opts.on(
            '-u', '--[no-]assign [<user>]', 'assign to specified user'
          ) do |assignee|
            assignee[:assignee] = assignee
          end
          opts.on(
            '-s', '--state <in>', %w(open closed),
            {'o'=>'open', 'c'=>'closed'}, 'open or closed'
          ) do |state|
            assigns[:state] = state
          end
          opts.on(
            '-M', '--[no-]milestone [<n>]', Integer, 'associate with milestone'
          ) do |milestone|
            assigns[:milestone] = milestone
          end
          opts.on(
            '-L', '--label <labelname>,...', Array, 'associate with label(s)'
          ) do |labels|
            assigns[:labels] = labels
          end
          opts.separator ''
        end
      end

      def execute
        require_issue
        require_repo

        options.parse! args

        i = throb {
          api.patch "/repos/#{repo}/issues/#{issue}", assigns
        }
        puts format_issue(i)
      end
    end
  end
end
