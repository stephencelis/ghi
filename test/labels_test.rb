require "test/unit"
require "helper"
require "pp"

class Test_labels < Test::Unit::TestCase
  def setup
    gen_token
    @repo_name=create_repo
  end

  def test_delete_labels
    open_issue @repo_name

    tmp_labels=get_issue[:labels]

    `#{ghi_exec} label 1 -d "#{tmp_labels.join(",")}" -- #{@repo_name}`

    response_issue=get_body("repos/#{@repo_name}/issues/1","Issue does not exist")

    assert_equal([],response_issue["labels"],"Labels not deleted properly")
  end

  def test_add_labels
    open_issue @repo_name

    tmp_labels=get_issue(1)[:labels]

    `#{ghi_exec} label 1 -a "#{tmp_labels.join(",")}" -- #{@repo_name}`

    response_issue=get_body("repos/#{@repo_name}/issues/1","Issue does not exist")

    tmp=tmp_labels+get_issue[:labels]

    assert_equal(tmp.uniq.sort,extract_labels(response_issue),"Labels not added properly")
  end

  def test_replace_labels
    open_issue @repo_name

    tmp_labels=get_issue(1)[:labels]

    `#{ghi_exec} label 1 -f "#{tmp_labels.join(",")}" -- #{@repo_name}`

    response_issue=get_body("repos/#{@repo_name}/issues/1","Issue does not exist")

    assert_equal(tmp_labels.uniq.sort,extract_labels(response_issue),"Labels not replaced properly")
  end

  def teardown
    delete_repo(@repo_name)
    delete_token
  end
end
