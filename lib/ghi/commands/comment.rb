module GHI
  module Commands
    class Comment < Command
      attr_accessor :comment

      #   usage: ghi comment [options] <issueno> [[<user>/]<repo>]
      #   
      #       -l, --list                       list comments
      #       -v, --verbose                    list events, too
      #           --amend                      amend previous comment
      #       -D, --delete                     delete previous comment
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi comment [options] <issueno> [[<user>/]<repo>]
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
          opts.separator ''
        end
      end

      def execute
        require_issue
        require_repo
        self.action ||= 'create'
        options.parse! args
        extract_repo args.pop

        case action
        when 'list'
          comments = index
          puts format_comments(comments)
        when 'create'
          create
        when 'update', 'destroy'
          comments = index
          self.comment = comments.find { |c|
            c['user']['login'] == Authorization.username
          }
          if comment
            send action
          else
            abort 'No recent comment found.'
          end
        end
      rescue Client::Error => e
        abort e.message
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
        if assigns[:body].nil?
          warn 'Missing argument: -m'
          abort options.to_s
        end
      end
    end
  end
end
