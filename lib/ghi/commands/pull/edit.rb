module GHI
  module Commands
    class Pull::Edit < Pull
      def options
        OptionParser.new do |opts|
          opts.banner = "edit - edits the title and body of your pull request"
          opts.on('-s', '--show', 'show the PR after successful edition') { @show = true }
        end
      end

      def execute
        subcommand_execute

        editor.start(template)
        # Note that we won't allow an empty body! While it's technically
        # possible, this might be a good chance to enforce good habits...
        editor.require_content_for(:title, :body)
        editor.check_for_changes(title: title, body: body)
        editor.unlink

        begin
          @pr = edit_pull_request
          puts "Pull request successfully edited."
          show_pull_request if @show
        rescue
          # TODO
        end
      end

      private

      def edit_pull_request
        throb { api.patch(pull_uri, editor.content) }.body
      end

      def title
        pr['title']
      end

      def body
        pr['body']
      end

      def editor
        @editor ||= Editor.new('GHI_PULL_REQUEST_EDIT')
      end

      def template
<<EOF
@ghi-title@ #{title}

#{body}
#{template_explanation}
EOF
      end

      def template_explanation
<<EOF
# Edit you pull request. You can edit the title, but please don't touch
# the keyword itself.  Trailing lines starting with '#' (like these)
# will be ignored, and empty messages will not be submitted. Issues are
# formatted with GitHub Flavored Markdown (GFM):
#
#   http://github.github.com/github-flavored-markdown
EOF
      end
    end
  end
end
