require "test/unit"
require "helper"
require "pp"

class Test_show < Test::Unit::TestCase
  def setup
    gen_token
    @repo_name=create_repo
  end

  def test_show
    issue=get_issue
    milestone=get_milestone
    comment=get_comment

    open_issue @repo_name
    create_comment @repo_name

    show_output = `#{ghi_exec} show 1 -- #{@repo_name}`

    assert_match(/\A#1: #{issue[:title]}\n/,show_output,"Title not proper")
    assert_match(/^@#{ENV["GITHUB_USER"]} opened this issue/,show_output,"Opening user not proper")
    assert_match(/^@#{ENV["GITHUB_USER"]} is assigned/,show_output,"Assigned user not proper")

    labels_str=""
    issue[:labels].sort.each do |tmp|
      labels_str+="\\[#{tmp}\\] "
    end
    labels_str.strip!

    assert_match(/#{labels_str}/,show_output,"labels not present")
    assert_match(/Milestone #1: #{milestone[:title]}/,show_output,"Milestone not proper")
    assert_match(/@#{ENV["GITHUB_USER"]} commented/,show_output,"Comment creator not proper")
    assert_match(/#{comment}/,show_output,"Comment not proper")
  end

  def teardown
    delete_repo(@repo_name)
    delete_token
  end
end
