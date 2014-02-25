module GHI
  module Commands
    class Pull::Fetch < Pull
      def options
        OptionParser.new do |opts|
          opts.banner = "fetch - creates local branches out of pull requests"
          opts.separator ''
          opts.on('-b', '--branch <branch>', 'target branch, default: <pr_no>_PR, e.g. 128_PR') do |branch|
            @branch = branch
          end
          opts.on('-c', '--checkout', 'move to your new branch after fetching') do
            @checkout = true
          end
        end
      end

      def execute
        subcommand_execute

        fetch_branch
        checkout_branch if @checkout
      end

      private

      def branch
        @branch ||= "#{issue}_PR"
      end

      # TODO should this point to upstream and just fallback to origin?
      def fetch_branch
        `git fetch origin refs/pull/#{issue}/head:#{branch}`
      end

      def checkout_branch
        `git checkout #{branch}`
      end
    end
  end
end
