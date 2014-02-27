module GHI
  module Commands
    class Show < Command
      attr_accessor :patch, :web

      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi show <issueno>'
          opts.separator ''
          opts.on('-p', '--patch') { self.patch = true }
          opts.on('-w', '--web', 'View the issue in your web browser') { self.web = true }
        end
      end

      def execute
        require_issue
        require_repo
        options.parse! args
        patch_path = "pull/#{issue}.patch" if patch # URI also in API...
        if web
          Web.new(repo).open patch_path || "issues/#{issue}"
        else
          if patch_path
            i = throb { Web.new(repo).curl patch_path }
            unless i.start_with? 'From'
              warn 'Patch not found'
              abort
            end
            page do
              no_color { puts i }
              break
            end
          else
            # At this point we don't know whether the issue is a real issue
            # or a pull request.
            # We request both at the same time: If a pull request shows up,
            # we create an instance of Pull::Show and present the PR, otherwise
            # we show the plain issue or the error message.
            i, pr = try_getting_issue_and_pr
            pr ? show_pull_request(pr) : show_issue(i)
          end
        end
      end

      private

      def try_getting_issue_and_pr
        i  = lambda { throb { api.get issue_uri }.body }
        pr = lambda { api.get(pull_uri).body rescue nil }

        do_threaded(i, pr)
      end

      def show_pull_request(pr)
        obj = Pull::Show.new
        obj.pr = pr
        obj.show_pull_request
      end

      def show_issue(i)
        page do
          puts format_issue(i)
          output_issue_comments(i['comments'])
          break
        end
      end
    end
  end
end
