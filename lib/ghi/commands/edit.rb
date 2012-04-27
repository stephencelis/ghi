module GHI
  module Commands
    class Edit < Command
      attr_accessor :editor

      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi edit [options] <issueno>
EOF
          opts.separator ''
          opts.on(
            '-m', '--message [<text>]', 'change issue description'
          ) do |text|
            next self.editor = true if text.nil?
            assigns[:title], assigns[:body] = text.split(/\n+/, 2)
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
            (assigns[:labels] ||= []).concat labels
          end
          opts.separator ''
          opts.separator 'Pull request options'
          opts.on(
            '-H', '--head [[<user>:]<branch>]',
            'branch where your changes are implemented',
            '(defaults to current branch)'
          ) do |head|
            self.action = 'pull'
            assigns[:head] = head
          end
          opts.on(
            '-b', '--base [<branch>]',
            'branch you want your changes pulled into', '(defaults to master)'
          ) do |base|
            self.action = 'pull'
            assigns[:base] = base
          end
          opts.separator ''
        end
      end

      def execute
        self.action = 'edit'
        require_issue
        require_repo
        options.parse! args
        case action
        when 'edit'
          begin
            if editor || assigns.empty?
              i = throb { api.get "/repos/#{repo}/issues/#{issue}" }.body
              e = Editor.new "GHI_ISSUE_#{issue}"
              message = e.gets format_editor(i)
              e.unlink "There's no issue." if message.nil? || message.empty?
              assigns[:title], assigns[:body] = message.split(/\n+/, 2)
            end
            if assigns[:title] && i
              titles_match = assigns[:title].strip == i['title'].strip
              if assigns[:body]
                bodies_match = assigns[:body].to_s.strip == i['body'].to_s.strip
              end
              if titles_match && bodies_match
                e.unlink if e
                abort 'No change.' if assigns.dup.delete_if { |k, v|
                  [:title, :body].include? k
                }
              end
              throb { api.post "/repos/#{repo}/pulls", assigns }.body
              puts "Issue ##{issue} tracked to pull from #{assigns[:head]}."
            end
            i = throb { api.patch "/repos/#{repo}/issues/#{issue}", assigns }.body
            puts format_issue(i)
            puts 'Updated.'
            e.unlink if e
          rescue Client::Error => e
            error = e.errors.first
            abort "%s %s %s %s." % [
              error['resource'],
              error['field'],
              [*error['value']].join(', '),
              error['code']
            ]
          end
        when 'pull'
          begin
            assigns[:issue] = issue
            assigns[:base] ||= 'master'
            head = begin
              if ref = %x{
                git rev-parse --abbrev-ref HEAD@{upstream} 2>/dev/null
              }.chomp!
                ref.split('/').last if $? == 0
              end
            end
            assigns[:head] ||= head
            if assigns[:head]
              assigns[:head].sub!(/:$/, ":#{head}")
            else
              abort "fatal: HEAD can't be null"
            end
            throb { api.post "/repos/#{repo}/pulls", assigns }
            base = [repo.split('/').first, assigns[:base]].join ':'
            puts 'Issue #%d set up to track remote branch %s against %s.' % [
              issue, assigns[:head], base
            ]
          rescue Client::Error => e
            abort e.errors.last['message'].sub /^base /, ''
          end
        end
      end
    end
  end
end
