module GHI
  module Commands
    class Open < Command
      attr_accessor :editor
      attr_accessor :web

      def options
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
            if text
              assigns[:title], assigns[:body] = text.split(/\n+/, 2)
            else
              self.editor = true
            end
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
            (assigns[:labels] ||= []).concat labels
          end
          opts.on('-w', '--web') { self.web = true }
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
          if web
            Web.new(repo).open 'issues/new'
          else
            unless args.empty?
              assigns[:title], assigns[:body] = args.join(' '), assigns[:title]
            end
            assigns[:title] = args.join ' ' unless args.empty?
            if assigns[:title].nil? || editor
              message = Editor.gets format_editor(assigns)
              abort "There's no issue?" if message.nil? || message.empty?
              assigns[:title], assigns[:body] = message.split(/\n+/, 2)
            end
            i = throb { api.post "/repos/#{repo}/issues", assigns }.body
            puts format_issue(i)
            puts 'Opened.'
          end
        end
      rescue Client::Error => e
        error = e.errors.first
        abort "%s %s %s %s." % [
          error['resource'],
          error['field'],
          [*error['value']].join(', '),
          error['code']
        ]
      end
    end
  end
end
