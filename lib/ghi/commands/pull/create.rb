module GHI
  module Commands
    class Pull::Create < Pull
      def options
        OptionParser.new do |opts|
          opts.banner = "create - creates a new pull request from your editor"
          opts.separator ''
          opts.on('-s', '--show', 'show the PR after successful creation') { @show = true }
        end
      end

      def execute
        subcommand_execute(true)

        editor.start(template)
        # Note that we won't allow an empty body! While it's technically
        # possible, this might be a good chance to enforce good habits...
        editor.require_content_for(:title, :base, :head, :body)
        editor.check_uniqueness(:base, :head)
        editor.unlink

        begin
          new_pr = create_pull_request
          @issue = new_pr['number']
          puts "Pull request ##{issue} successfully created."

          # GitHub needs to analyze the new pull request - we have to
          # call the API again to receive it with all stats updated.
          #
          # show_pull_request does this by calling pr - which usually
          # caches such an API call. It cannot have been called at this
          # point, a fresh request is therefore made.
          show_pull_request if @show
        rescue
          # TODO
          # Possible errors:
          #   head wasn't pushed
          #   base doesn't exist
          #   PR already exists
          puts "Something went wrong."
        end
      end

      private

      def create_pull_request
        throb { api.post create_uri, editor.content }.body
      end

      def create_uri
        "/repos/#{repo}/pulls"
      end

      # We cannot name these method head and base - something like that
      # already exists. In most cases it makes no difference, as they
      # will contain the same info anyway. However if a user edits this
      # information in his editor, they are out of sync and a subsequent
      # show operation will be wrong.
      def new_head
        @head ||= "#{origin[:user]}:#{current_branch}"
      end

      def new_base
        @base ||= "#{(upstream || origin)[:user]}:master"
      end

      def title
        current_branch.capitalize.split('_').join(' ')
      end

      def editor
        @editor ||= Editor.new('GHI_PULL_REQUEST.ghi')
      end

      def template
        <<EOF
@ghi-title@ #{title}
@ghi-head@  #{new_head}
@ghi-base@  #{new_base}

#{template_explanation}
EOF
      end

      def template_explanation
super <<EOF
Please explain the pull request. You can edit title, head and base but
don't touch the keywords itself. Use the empty section as the message's
body. Trailing lines starting with '#' (like these) will be ignored,
and empty messages will not be submitted. Issues are formatted with
GitHub Flavored Markdown (GFM):

  http://github.github.com/github-flavored-markdown
EOF
      end
    end
  end
end
