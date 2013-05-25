module GHI
  module Commands
    class Show < Command
      attr_accessor :patch, :web, :print_link

      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi show <issueno>'
          opts.separator ''
          opts.on('-p', '--patch') { self.patch = true }
          opts.on('-w', '--web') { self.web = true }
          opts.on('-P', '--print-link') { self.print_link = true }
        end
      end

      def execute
        require_issue
        require_repo
        options.parse! args
        patch_path = "pull/#{issue}.patch" if patch # URI also in API...
        puts "https://github.com/#{repo}/issues/#{issue}" if print_link
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
            page do
              puts format_issue(i)
              n = i['comments']
              if n > 0
                puts "#{n} comment#{'s' unless n == 1}:\n\n"
                Comment.execute %W(-l #{issue} -- #{repo})
              end
              break
            end
          end
        end
      end
    end
  end
end
