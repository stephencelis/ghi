module GHI
  module Commands
    class Edit < Command
      attr_accessor :edit

      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi edit [options] <issueno>
EOF
          opts.separator ''
          opts.on(
            '-m', '--message [<text>]', 'change issue description'
          ) do |text|
            next self.edit = true if text.nil?
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
            (assigns[:labels] ||= []).concat labels
          end
          opts.separator ''
        end
      end

      def execute
        require_issue
        require_repo
        options.parse! args
        if edit || assigns.empty?
          i = throb { api.get "/repos/#{repo}/issues/#{issue}" }.body
          message = Editor.gets format_editor(i)
          abort "There's no issue." if message.nil? || message.empty?
          assigns[:title], assigns[:body] = message.split(/\n+/, 2)
        end
        if assigns[:title] && i
          titles_match = assigns[:title].strip == i['title'].strip
          if assigns[:body]
            bodies_match = assigns[:body].to_s.strip == i['body'].to_s.strip
          end
          if titles_match && bodies_match
            abort 'No change.' if assigns.dup.delete_if { |k, v|
              [:title, :body].include? k
            }
          end
        end
        i = throb { api.patch "/repos/#{repo}/issues/#{issue}", assigns }.body
        puts format_issue(i)
        puts 'Updated.'
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
