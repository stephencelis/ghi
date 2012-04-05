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
          opts.on '-m', '--message [<text>]', 'describe issue' do |text|
            assigns[:title], assigns[:body] = text.split(/\n+/, 2) if text
          end
          opts.on(
            '-u', '--[no-]assign [<user>]', 'assign to specified user'
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
        require_repo
        self.action = 'create'

        if extract_issue
          Edit.execute args.push('-so', issue, '--', repo)
          exit
        end

        options.parse! args

        case action
        when 'index'
          if assigns.key? :assignee
            args.unshift assigns[:assignee] if assigns[:assignee]
            args.unshift '-u'
          end
          List.execute args.push('--', repo)
        when 'create'
          if assigns[:title].nil?
            message = Editor.gets format_editor
            abort "There's no issue?" if message.nil? || message.empty?
            assigns[:title], assigns[:body] = message.split(/\n+/, 2)
          end
          i = throb { api.post "/repos/#{repo}/issues", assigns }.body
          puts format_issue(i)
          puts 'Opened.'
        end
      end
    end
  end
end
