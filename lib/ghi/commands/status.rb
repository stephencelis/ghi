module GHI
  module Commands
    class Status < Command

			def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi status'
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
				
				require_repo
				res = throb { api.get "/repos/#{repo}" }.body

				if res['has_issues']
					puts "Issues are enabled for this repo"
				else
					puts "Issues are not enabled for this repo"
				end

			end
		end
	end
end
