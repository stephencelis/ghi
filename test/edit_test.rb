require "test/unit"
require "helper"
require "pp"

class Test_edit < Test::Unit::TestCase
	def setup
		gen_token
		@repo_name=create_repo
	end

	def test_edit_issue
		open_issue @repo_name

		issue=get_issue 1

		create_milestone @repo_name, 1

		`#{ghi_exec} edit 1 "#{issue[:title]}" -m "#{issue[:des]}" -L "#{issue[:labels].join(",")}" -M 2 -s open -u "#{ENV['GITHUB_USER']}" -- #{@repo_name}`

		response_issue=get_body("repos/#{@repo_name}/issues/1","Issue does not exist")

		assert_equal(issue[:title],response_issue["title"],"Title not proper")
		assert_equal(issue[:des],response_issue["body"],"Descreption not proper")
		assert_equal(issue[:labels].uniq.sort,extract_labels(response_issue),"Labels do not match")
		assert_equal("open",response_issue["state"],"Issue state not changed")
		assert_equal(2,response_issue["milestone"]["number"],"Milestone not proper")
		assert_not_equal(nil,response_issue["assignee"],"No user assigned")
		assert_equal(ENV['GITHUB_USER'],response_issue["assignee"]["login"],"Not assigned to proper user")
	end

	def teardown
		delete_repo(@repo_name)
		delete_token
	end
end
