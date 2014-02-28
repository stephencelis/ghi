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

      def diff
        output_from_html(:diff)
      end

      def patch
        output_from_html(:patch)
      end

      def diff_with_comments
        diff = commented_diff
        page { puts diff }
      end

      def commented_diff(comment_marker = '')
        # Make sure the lazy evaluation of repo has been run before -
        # we'll get an ugly race condition otherwise
        require_repo

        # Get the diff and the review comments in parallel
        diff_call = lambda { throb { get_html web_uri('diff') } }
        comm_call = lambda { api.get(review_comments_uri).body }
        diff, comments = do_threaded(diff_call, comm_call)

        # Review comments also contain outdated comments - we don't
        # need them
        delete_outdated_comments(comments)

        # We want to insert something into the diff at specific positions.
        # These positions are identified by diff hunks. We can look up these
        # hunks in the diff to know where we have to insert the comment.
        # However as soon as we start to insert stuff, the diff itself is
        # invalidated: Looking up positions by hunks therefore won't work
        # anymore.
        # This can be avoided when the order of insertion is right: We need
        # to do it from the bottom up, so that the upper parts don't go out
        # of sync with the original diff.
        # We sort them by their position and their creation date inside the
        # diff.
        # We also group the per hunk, which is a little more efficient when
        # multiple comments of the same code piece need to be displayed.
        grouped_comment_ids = group_by_diff_hunk(comments)

        # To get the formatting we want, only placeholders are inserted at
        # first. Right after that the diff is formatted.
        # Then we'll replace the placeholders with formatted comments -
        # syntax highlighting and all enabled.
        insert_place_holders(diff, grouped_comment_ids)
        formatted = format_diff(diff)
        replace_placeholders(formatted, comments, comment_marker)
        formatted
      end

      def delete_outdated_comments(comments)
        comments.keep_if { |comment| comment['position'] }
      end

      def group_by_diff_hunk(comments)
        sorted= comments.sort_by do |c|
          [c['position'], c['created_at'].size]
        end
        sorted.each_with_object(hash_with_default_array) do |comment, h|
          h[comment['diff_hunk']] << comment['id']
        end
      end

      def insert_place_holders(diff, comments)
        # insert from the bottom up, so we don't destroy the indices
        comments.keys.reverse.each do |hunk|
          # + 1 because we want to place our placeholder right after the new
          # line that follows our hunk
          index = diff.index(hunk) + hunk.size + 1
          ids = comments[hunk]
          placeholders = ids.map { |id| placeholder(id) }.join
          diff.insert(index, placeholders)
        end
      end

      def placeholder(id)
        "@ghi-comment-#{id}@"
      end

      def replace_placeholders(diff, comments, comment_marker)
        comments.each do |comment|
          ph = placeholder(comment['id'])
          c  = "\n" + format_comment(comment).chop # one newline less
          c  = prepend_each_line(c, comment_marker)
          diff.sub!(ph, c)
        end
      end

      def prepend_each_line(lines, marker)
        lines.each_line.map do |line|
          "#{marker}#{line}"
        end.join
      end

      def hash_with_default_array
        Hash.new { |h, k| h[k] = [] }
      end

      def comment
        # We need to know the current pull requests head to create comments.
        # Let's do it while the user spends time in the editor, he won't notice.
        ed = lambda { editor.start(no_color { commented_diff('#|# ') }) }
        pr = lambda { api.get(pull_uri).body['head']['sha'] rescue nil }
        _, sha = do_threaded(ed, pr)

        # Check the comments in Editor for the following.
        editor.cut_diff_comments
        comments = editor.extract_new_comments

        throb do
          threads = comments.map do |comment|
            Thread.new do
              comment['commit_id'] = sha
              api.post(review_comments_uri, comment)
            end
          end
          threads.each(&:join)
        end

        # Unlink afterwards, in case there is an error from GitHub's side -
        # something like a server error. If it really fails, the user can
        # just repeat the command and won't loose the changes he's made.
        editor.unlink
        puts "#{count_with_plural(comments.size, 'comment')} created."
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

      def review_comments_uri
        "#{pull_uri}/comments"
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

      def editor
        @editor ||= Editor.new('GHI_PR_DIFF_COMMENTS')
      end
    end
  end
end
