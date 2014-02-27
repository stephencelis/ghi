module GHI
  module Commands
    class Pull::Show < Pull
      def options
        OptionParser.new do |opts|
          opts.banner = "show - displays details of a pull request"
          opts.on('-c', '--commits', 'show associated commits') { commits; abort }
          opts.on('-f', '--files', 'show changed files') { files; abort }
          opts.on('-d', '--diff', 'show diff') { diff; abort }
          opts.on('-p', '--patch', 'show patch') { patch; abort}
        end
      end

      def execute
        subcommand_execute
        show_pull_request
      end

      def commits
        show_additional_data(:commits)
      end

      def files
        show_additional_data(:files)
      end

      def diff
        output_from_html(:diff)
      end

      def patch
        output_from_html(:patch)
      end

      def show_additional_data(type)
        res = throb { api.get "#{pull_uri}/#{type}" }.body
        page do
          puts send("format_#{type}", res)
          break
        end
      end

      def output_from_html(type)
        res = throb { get_html "pull/#{issue}.#{type}" }
        page do
          puts format_diff(res)
          break
        end
      end
    end
  end
end
