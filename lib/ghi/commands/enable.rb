module GHI
  module Commands
    class Enable < Command

      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi enable'
        end
      end

      def execute
        begin
          options.parse! args
          @repo ||= ARGV[0] if ARGV.one?
        rescue OptionParser::InvalidOption => e
          fallback.parse! e.args
          retry
        end
        repo_name = require_repo_name
        unless repo_name.nil?
          patch_data = {}
          patch_data[:name] = repo_name
          patch_data[:has_issues] = true
          res = throb { api.patch "/repos/#{repo}", patch_data }.body
          if res['has_issues']
            puts "Issues are now enabled for this repo"
          else
            puts "Something went wrong enabling issues for this repo"
          end
        end
      end

    end

  end
end
