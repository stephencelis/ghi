module GHI
  module Commands
    class Open < Command
      def options
        #--
        # TODO: Support shortcuts, e.g,
        #
        #   ghi open "Issue Title"
        #++
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi open [options]
   or: ghi reopen [options] <issueno>
EOF
          opts.separator ''
          opts.on '-l', '--list', 'list open tickets' do
            self.action = 'index'
          end
          opts.separator ''
          opts.separator 'Issue modification options'
          opts.on '-m', '--message <text>', 'describe issue' do |text|
            assigns[:title], assigns[:body] = text.split(/\n+/, 2)
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
          if assigns[:title].nil? # FIXME: Open $EDITOR
            warn "Missing argument: -m"
            abort options.to_s
          end
          i = throb { api.post "/repos/#{repo}/issues", assigns }.body
          puts format_issue(i)
          puts 'Opened.'
        end
      end
    end
  end
end
