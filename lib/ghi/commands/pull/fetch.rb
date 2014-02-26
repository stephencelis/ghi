module GHI
  module Commands
    class Pull::Fetch < Pull
      def options
        OptionParser.new do |opts|
          opts.banner = "fetch - creates local branches out of pull requests"
          opts.on('-b', '--branch <branch>', 'target branch, defaults to <pull_reqest_no>_PR') do |branch|
            @branch = branch
          end
          opts.on('-c', '--checkout', 'checkout to your new branch after fetching') do
            @checkout = true
          end
        end
      end

      def execute
        require_issue
        extract_issue
        options.parse!(args)

        fetch_branch
        checkout_branch if @checkout
      end

      private

      def branch
        @branch ||= "#{issue}_PR"
      end

      def fetch_branch
        `git fetch origin refs/pull/#{issue}/head:#{branch}`
      end

      def checkout_branch
        `git checkout #{branch}`
      end
    end
  end
end
