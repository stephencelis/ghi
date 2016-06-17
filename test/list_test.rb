require "test/unit"
require "helper"
require "pp"

class Test_list < Test::Unit::TestCase
	def setup
		gen_token
		@repo_name=create_repo
	end

	def test_list
		tmp_issues=get_issue(-1)
		for i in 0..(tmp_issues.length-1)
			open_issue @repo_name, i
		end
		list_output=`#{ghi_exec} list -- "#{@repo_name}"`

		list_lines=list_output.lines

		assert_equal(tmp_issues.length+1,list_lines.length,"Not enough lines in output")
		assert_match(/^# #{@repo_name} open issues$/,list_lines[0],"Heading not proper")

		tmp_issues.length.downto(1) do |i|
			issue_title=tmp_issues[i-1][:title]
			milestone_title=get_milestone(tmp_issues[i-1][:milestone]-1)[:title]
			tmp_line=list_lines[-i].strip

			labels_str=""
			tmp_issues[i-1][:labels].sort.each do |tmp|
				labels_str+="\\[#{tmp}\\] "
			end
			labels_str.strip!

			assert_match(/^#{i}  #{issue_title} #{labels_str} #{milestone_title} @#{ENV["GITHUB_USER"]}/,tmp_line,"Issue no #{i} not proper")
		end
	end

	def teardown
		delete_repo(@repo_name)
		delete_token
	end
end
