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
          opts.on '-m', '--message <text>', 'comment body' do |text|
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
          Close.execute %W(-m #{assigns[:body]} #{issue} -- #{repo})
        end
      end

      protected

      def index
        throb { api.get uri }
      end

      def create
        require_body
        throb { api.post uri, assigns }
        puts 'Comment created.'
      end

      def update
        require_body
        throb { api.patch uri, assigns }
        puts 'Comment updated.'
      end

      def destroy
        throb { api.delete uri }
        puts 'Comment deleted.'
      end

      private

      def uri
        comment ? comment['url'] : "/repos/#{repo}/issues/#{issue}/comments"
      end

      def require_body
        if assigns[:body].nil? # FIXME: Open $EDITOR.
          warn 'Missing argument: -m'
          abort options.to_s
        end
      end
    end
  end
end
