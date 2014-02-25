module GHI
  module Commands
    class Pull::Close < Pull
      def options
        OptionParser.new do |opts|
          opts.banner = "close - closes a pull request without merging"
          opts.separator ''
          opts.on('-s', '--show', 'show the PR after closing') { @show = true }
        end
      end

      def execute
        subcommand_execute

        begin
          @pr = close_pull_request
          puts 'Unmerged pull request closed.'
          show_pull_request if @show
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
