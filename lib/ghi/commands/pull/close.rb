module GHI
  module Commands
    class Pull::Close < Pull::Show
      def options
        "close - closes a pull request without merging"
      end

      def execute
        handle_help_request
        require_issue
        extract_issue

        begin
          @pr = close_pull_request
          honor_the_issue_contract
          show_pull_request
          puts 'Unmerged pull request closed.'
        rescue
          # TODO
        end
      end

      private

      def close_pull_request
        throb { api.patch(pull_uri, state: 'closed') }.body
      end
    end
  end
end
