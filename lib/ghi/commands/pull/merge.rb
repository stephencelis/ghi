module GHI
  module Commands
    class Pull::Merge < Pull
      def options
        OptionParser.new do |opts|
          opts.banner = "merge - tries to automatically merge a pull request, like GitHub's Merge Button"
          opts.separator ''
          opts.on('-p', '--pull', 'pulls locally after a successful merge') do
            @pull = true
          end
          opts.on('-r', '--rebase', 'pulls locally through rebase') do
            @rebase = true
          end
          opts.on('-m', '--message', "the merge commit message body - default: PR title") do |message|
            abort "Commit message must not be empty" if message.empty?
            @commit_messge = message
          end
          opts.on('-e', '--edit', 'edit the commit message with your editor') do
            @edit = true
          end
        end
      end

      def execute
        subcommand_execute

        obtain_message_from_editor if @edit
        abort already_merged if merged?
        abort dirty_pull_request unless mergeable?
        ask_for_continuation if needs_rebase?

        begin
          merge_pull_request
          puts fg('2cc200') { 'Merge successful!'}
          pull_changes if pull_requested?
        rescue
          abort "Automatic merging impossible."
        end
      end

      private

      def ask_for_continuation
        print rebase_warning
        abort "\nThanks! Your commit history is grateful." unless $stdin.gets.chomp == 'Y'
      end

      def rebase_warning
        # Beware and add the last whitespace separately. If we just leave it trailing
        # in the heredoc, editor, git-hooks etc. might eat it away.
<<EOF.strip + ' '
\b#{fg('e1811d') { "#{head} and #{base} have diverged!" }}

To retain a clean commit history it is recommended to rebase before merging.
Do you really want to do this? (type Y to continue)
EOF
      end

      def already_merged
        "Pull request has already been merged.\n" + more_info
      end

      def dirty_pull_request
        "Cannot merge a dirty pull request.\n" + more_info
      end

      def more_info
        "See 'ghi pull show #{issue}' for further information."
      end

      def commit_message
        @commit_message ||= pr['title']
      end

      def merge_pull_request
        throb { api.put merge_uri, commit_message: commit_message }
      end

      def pull_changes
        cmd = 'pull' if @pull
        cmd = 'pull --rebase' if @rebase
        branch = pr['base']['ref']

        `git checkout #{branch}`
        `git #{cmd} origin #{branch}`
      end

      def merge_uri
        "#{pull_uri}/merge"
      end

      def merged?
        pr['merged']
      end

      def mergeable?
        pr['mergeable']
      end

      def pull_requested?
        abort "...but don't know whether you want to pull or rebase." if @rebase && @pull
        @rebase || @pull
      end

      def obtain_message_from_editor
        editor.start(template + template_explanation)
        editor.require_content_for(:body)
        editor.unlink
        @commit_message = editor.content[:body]
      end

      def editor
        @editor ||= Editor.new('GHI_PULL_REQUEST_MERGE.ghi')
      end

      def template
        "#{pr['title']}\n"
      end

      def template_explanation
        super <<EOF
Edit the merge commits body. Its title is automatically set by GitHub:
'#{gh_merge_title}'. Trailing lines starting with '#{IGNORE_MARKER}'
(like these) will be ignored, and empty message won't be submitted.
EOF
      end

      def gh_merge_title
        "Merge pull request ##{issue} from #{base.sub(':', '/')}"
      end
    end
  end
end
