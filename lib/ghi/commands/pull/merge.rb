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
          opts.on('-m', '--message', "message used in the merge commits body - defaults to the PR's title") do |message|
            abort "Commit message must not be empty" if message.empty?
            @commit_messge = message
          end
        end
      end

      def execute
        subcommand_execute

        begin
          merge_pull_request
        rescue
          abort "Automatic merging impossible."
        end
      end

      private

      def commit_message
        @commit_message
      end

      def merge_pull_request
        throb { api.put merge_uri, commit_message: commit_message }
      end

      def merge_uri
        "#{pull_uri}/merge"
      end
    end
  end
end
