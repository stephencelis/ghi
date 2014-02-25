module GHI
  module Commands
    class Show < Command
      attr_accessor :patch, :web

      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi show <issueno>'
          opts.separator ''
          opts.on('-p', '--patch') { self.patch = true }
          opts.on('-w', '--web') { self.web = true }
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
            i = throb { api.get "/repos/#{repo}/issues/#{issue}" }.body
            determine_merge_status(i) if pull_request?(i)
            page do
              puts format_issue(i)
              output_issue_comments(i['comments'])
              break
            end
          end
        end
      end

      private

      def pull_request?(issue)
        issue['pull_request']['html_url']
      end

      def determine_merge_status(pr)
        pr['merged'] = true if pr['state'] == 'closed' && merged?
      end

      def merged?
        # API returns with a Not Found error when the PR is not merged
        api.get "/repos/#{repo}/pulls/#{issue}/merge" rescue false
      end
    end
  end
end
