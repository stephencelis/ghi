module GHI
  module Commands
    class Pull::Show < Pull
      def options
        OptionParser.new do |opts|
          opts.banner = "show - displays details of a pull request"
          opts.on('-c', '--commits', 'show associated commits') { commits; abort }
          opts.on('-f', '--files', 'show changed files') { files; abort }
          opts.on('-p', '--patch', 'show patch') { patch; abort}
          opts.on('-d', '--diff', 'show diff with review comments') { diff_with_comments; abort }
          opts.on('-D', '--no-comment-diff', 'show diff without review comments') { diff; abort }
          opts.on('-C', '--comment', 'description') { comment; abort }
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

      def web_uri(type)
        "pull/#{issue}.#{type}"
      end

      def output_from_html(type)
        res = throb { get_html web_uri(type)}
        page do
          # use the original $stdout.puts, as puts is monkey patched
          # to highlight usernames - not cool when you display code only
          $stdout.puts format_diff(res)
          break
        end
      end
    end
  end
end
