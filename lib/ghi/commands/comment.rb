module GHI
  module Commands
    class Comment < Command
      attr_accessor :comment

      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi comment [options] <issueno>
EOF
          opts.separator ''
          opts.on '-l', '--list', 'list comments' do
            self.action = 'list'
          end
          # opts.on '-v', '--verbose', 'list events, too'
          opts.separator ''
          opts.separator 'Comment modification options'
          opts.on '-m', '--message [<text>]', 'comment body' do |text|
            assigns[:body] = text
          end
          opts.on '--amend', 'amend previous comment' do
            self.action = 'update'
          end
          opts.on '-D', '--delete', 'delete previous comment' do
            self.action = 'destroy'
          end
          opts.on '--close', 'close associated issue' do
            self.action = 'close'
          end
          opts.separator ''
        end
      end

      def execute
        require_issue
        require_repo
        self.action ||= 'create'
        options.parse! args

        case action
        when 'list'
          res = index
          page do
            puts format_comments(res.body)
            break unless res.next_page
            res = throb { api.get res.next_page }
          end
        when 'create'
          create
        when 'update', 'destroy'
          res = index
          res = throb { api.get res.last_page } if res.last_page
          self.comment = res.body.reverse.find { |c|
            c['user']['login'] == Authorization.username
          }
          if comment
            send action
          else
            abort 'No recent comment found.'
          end
        when 'close'
          Close.execute [issue, '-m', assigns[:body], '--', repo].compact
        end
      end

      protected

      def index
        throb { api.get uri }
      end

      def create
        require_body
        c = throb { api.post uri, assigns }.body
        puts format_comment c
        puts 'Commented.'
      end

      def update
        require_body
        c = throb { api.patch uri, assigns }.body
        puts format_comment c
        puts 'Updated.'
      end

      def destroy
        throb { api.delete uri }
        puts 'Deleted.'
      end

      private

      def uri
        comment ? comment['url'] : "/repos/#{repo}/issues/#{issue}/comments"
      end

      def require_body
        return if assigns[:body]
        message = Editor.gets format_comment_editor(issue, comment)
        abort 'No comment.' if message.nil? || message.empty?
        abort 'No change.' if comment && message.strip == comment['body'].strip
        assigns[:body] = message if message
      end
    end
  end
end
