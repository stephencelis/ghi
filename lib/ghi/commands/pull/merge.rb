module GHI
  module Commands
    class Pull::Merge < Pull
      def options
        OptionParser.new do |opts|
          opts.banner = "merge - tries to automatically merge a pull request, like GitHub's Merge Button"
          opts.on('-p', '--pull', 'pulls the new commits locally after a successful merge') do |pull|
            @pull = true
          end
          opts.on('-r', '--rebase', 'pulls the new commits locally through rebase') do |rebase|
            @rebase = true
          end
          opts.on('-m', '--message', "used in the merge commits body - defaults to PR title") do |message|
            abort "Commit message must not be empty" if message.empty?
            @commit_messge = message
          end
        end
      end

      def execute
        subcommand_execute

        abort already_merged if merged?
        abort dirty_pull_request unless mergeable?
        ask_for_continuation if needs_rebase?

        begin
          merge_pull_request
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
        [
          "\b" + fg('e1811d') { "#{head} and #{base} have diverged!" },
          '',
          "To retain a clean commit history it is recommended to rebase before merging.",
          'Do you really want to do this? (type Y to continue) '
        ].join("\n")
      end

      def already_merged_message
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

      def merge_uri
        "#{pull_uri}/merge"
      end

      def merged?
        pr['merged']
      end

      def mergeable?
        pr['mergeable']
      end
    end
  end
end
