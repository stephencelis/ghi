module GHI
  module Commands
    class Open < Command
      attr_accessor :editor
      attr_accessor :web
      attr_accessor :outfile
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
          opts.on('-w', '--web') { self.web = true }
          opts.separator ''
          opts.separator 'Issue modification options'
          opts.on(
              '-m', '--message [<text>]', 'describe issue',
              "use line breaks to separate title from description"
          ) do |text|
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
          opts.on '--claim', 'assign to yourself' do
            assigns[:assignee] = Authorization.username
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
          opts.on(
            '-O', '--outfile <filename>...', 'write formatted issue to filename, not stdout'
          ) do |outfile|
            self.outfile = outfile
          end
          opts.separator ''
        end
      end

      def write_issue_id(issue)
          open(self.outfile, 'w') { |f|
            f.puts issue['number']
          }
      end

      def execute
        require_repo
        self.action = 'create'

        options.parse! args

        if GHI.config('ghi.infer-issue') != 'false' && extract_issue
          Edit.execute args.push('-so', issue, '--', repo)
          exit
        end

        case action
        when 'index'
          if assigns.key? :assignee
            args.unshift assigns[:assignee] if assigns[:assignee]
            args.unshift '-u'
          end
          args.unshift '-w' if web
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
              e = Editor.new 'GHI_ISSUE.md'
              message = e.gets format_editor(assigns)
              e.unlink "There's no issue?" if message.nil? || message.empty?
              assigns[:title], assigns[:body] = message.split(/\n+/, 2)
            end
            i = throb { api.post "/repos/#{repo}/issues", assigns }.body
            e.unlink if e
            self.write_issue_id(i) if self.outfile
            puts format_issue(i)
            puts "Opened on #{repo}."
          end
        end
      rescue Client::Error => e
        raise unless error = e.errors.first
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
