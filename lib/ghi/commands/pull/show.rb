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

      def diff_with_comments
        # make sure the lazy evaluation of repo has been run before -
        # we'll get an ugly race condition otherwise
        require_repo
        diff_call = lambda { throb { get_html web_uri('diff') } }
        comm_call = lambda { api.get("#{pull_uri}/comments").body }
        diff, comments = do_threaded(diff_call, comm_call)
        grouped_comment_ids = group_by_diff_hunk(comments)
        insert_place_holders(diff, grouped_comment_ids)
        formatted = format_diff(diff)
        replace_placeholders(formatted, comments)
        puts formatted
      end

      def group_by_diff_hunk(comments)
        comments.each_with_object(hash_with_default_array) do |comment, h|
          h[comment['diff_hunk']] << comment['id']
        end
      end

      def insert_place_holders(diff, comments)
        # insert from the bottom up, so we don't destroy the indices
        comments.keys.reverse.each do |hunk|
          index = diff.index(hunk) + hunk.size
          ids = comments[hunk]
          placeholders = ids.map { |id| "\n" + placeholder(id) }.join
          diff.insert(index, "\n" + placeholders)
        end
      end

      def placeholder(id)
        "@ghi-comment-#{id}@"
      end

      def replace_placeholders(diff, comments)
        comments.each do |comment|
          ph = placeholder(comment['id'])
          c  = format_comment(comment).strip
          diff.sub!(ph, "#{c}\n")
        end
      end

      def hash_with_default_array
        Hash.new { |h, k| h[k] = [] }
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
