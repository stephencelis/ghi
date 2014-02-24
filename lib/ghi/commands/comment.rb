module GHI
  module Commands
    class Comment < Command
      attr_accessor :comment
      attr_accessor :verbose
      attr_accessor :web

      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi comment [options] <issueno>
EOF
          opts.separator ''
          opts.on '-l', '--list', 'list comments' do
            self.action = 'list'
          end
          opts.on('-w', '--web') { self.web = true }
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
          opts.on '-v', '--verbose' do
            self.verbose = true
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
          get_requests(:index, :events)
          res = index
          page do
            elements = sort_by_creation(res.body + paged_events(events, res))
            puts format_comments_and_events(elements)
            break unless res.next_page
            res = throb { api.get res.next_page }
          end
        when 'create'
          if web
            Web.new(repo).open "issues/#{issue}#issue_comment_form"
          else
            create
          end
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
        @index ||= throb { api.get uri, :per_page => 100 }
      end

      def create message = 'Commented.'
        e = require_body
        c = throb { api.post uri, assigns }.body
        puts format_comment(c)
        puts message
        e.unlink if e
      end

      def update
        create 'Comment updated.'
      end

      def destroy
        throb { api.delete uri }
        puts 'Comment deleted.'
      end

      def events
        @events ||= begin
          events = []
          res = api.get(event_uri, :per_page => 100)
          loop do
            events += res.body
            break unless res.next_page
            res = api.get res.next_page
          end
          events
        end
      end

      private

      def get_requests(*methods)
        threads = methods.map do |method|
          Thread.new { send(method) }
        end
        threads.each { |t| t.join }
      end

      def uri
        if comment
          comment['url']
        else
          "/repos/#{repo}/issues/#{issue}/comments"
        end
      end

      def event_uri
        "/repos/#{repo}/issues/#{issue}/events"
      end

      def require_body
        assigns[:body] = args.join ' ' unless args.empty?
        return if assigns[:body]
        if issue && verbose
          i = throb { api.get "/repos/#{repo}/issues/#{issue}" }.body
        else
          i = {'number'=>issue}
        end
        filename = "GHI_COMMENT_#{issue}"
        filename << "_#{comment['id']}" if comment
        e = Editor.new filename
        message = e.gets format_comment_editor(i, comment)
        e.unlink 'No comment.' if message.nil? || message.empty?
        if comment && message.strip == comment['body'].strip
          e.unlink 'No change.'
        end
        assigns[:body] = message if message
        e
      end

      def paged_events(events, comments_res)
        if comments_res.next_page
          last_comment_creation = comments_res.body.last['created_at']
          events_for_this_page, @events = events.partition do |event|
            event['created_at'] < last_comment_creation
          end
          events_for_this_page
        else
          events
        end
      end
    end
  end
end
