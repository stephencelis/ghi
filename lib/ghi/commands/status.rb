module GHI
  module Commands
    class Status < Command

			def execute
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
