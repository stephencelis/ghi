module GHI
  module Commands
    class Open < Command
      #   usage: ghi open [options] [[<user>/]<repo>]
      #      or: ghi reopen [options] <issueno> [[<user>/]<repo>]
      #   
      #       -l, --list                       list open tickets
      #   
      #   Issue modification options
      #       -m, --message <text>             describe issue
      #       -u, --[no-]assign <user>         assign to specified user
      #       -M, --milestone <n>              associate with milestone
      #       -L, --label <labelname>...       associate with label(s)
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi open [options] [[<user>/]<repo>]
   or: ghi reopen [options] <issueno> [[<user>/]<repo>]
EOF
          opts.separator ''
          opts.on '-l', '--list', 'list open tickets' do
            self.action = 'index'
          end
          opts.separator ''
          opts.separator 'Issue modification options'
          opts.on '-m', '--message <text>', 'describe issue' do |text|
            assigns[:title], assigns[:description] = text.split(/\n+/, 2)
          end
          opts.on(
            '-u', '--[no-]assign <user>', 'assign to specified user'
          ) do |assignee|
            assigns[:assignee] = assignee
          end
          opts.on(
            '-M', '--milestone <n>', 'associate with milestone'
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
        self.action = 'create'

        if extract_issue
          Edit.new(args.unshift('-so', issue)).execute
          puts 'Reopened.'
          exit
        end

        options.parse! args

        case action
        when 'index'
          List.new(args).execute
        when 'create'
          extract_repo args.pop
          if assigns[:title].nil? # FIXME: Open $EDITOR
            warn "Missing argument: -m"
            abort options.to_s
          end
          i = throb { api.post "/repos/#{repo}/issues", assigns }
        end
      rescue Client::Error
      end
    end
  end
end
