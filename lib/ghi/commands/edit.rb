module GHI
  module Commands
    class Edit < Command
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi edit [options] <issueno>
EOF
          opts.separator ''
          opts.on(
            '-m', '--message <text>', 'change issue description'
          ) do |text|
            assigns[:title], assigns[:body] = text.split(/\n+/, 2)
          end
          opts.on(
            '-u', '--[no-]assign [<user>]', 'assign to specified user'
          ) do |assignee|
            assigns[:assignee] = assignee
          end
          opts.on(
            '-s', '--state <in>', %w(open closed),
            {'o'=>'open', 'c'=>'closed'}, "'open' or 'closed'"
          ) do |state|
            assigns[:state] = state
          end
          opts.on(
            '-M', '--[no-]milestone [<n>]', Integer, 'associate with milestone'
          ) do |milestone|
            assigns[:milestone] = milestone
          end
          opts.on(
            '-L', '--label <labelname>...', Array, 'associate with label(s)'
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
        i = throb { api.patch "/repos/#{repo}/issues/#{issue}", assigns }.body
        puts format_issue(i)
      end
    end
  end
end
