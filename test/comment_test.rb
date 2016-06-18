require "test/unit"
require "helper"
require "pp"

class Test_comment < Test::Unit::TestCase
  def setup
    gen_token
    @repo_name=create_repo
  end

  def test_comment
    open_issue @repo_name
    create_comment @repo_name
  end

  def test_comment_amend
    open_issue @repo_name
    create_comment @repo_name

    comment=get_comment 1

    `#{ghi_exec} comment --amend "#{comment}" 1 -- #{@repo_name}`

    response_body=get_body("repos/#{@repo_name}/issues/1/comments","Issue does not exist")

    assert_equal(1,response_body.length,"Comment does not exist")
    assert_equal(comment,response_body[-1]["body"],"Comment text not proper")
  end

  def test_comment_delete
    open_issue @repo_name
    create_comment @repo_name

    `#{ghi_exec} comment -D 1 -- #{@repo_name}`

    response_body=get_body("repos/#{@repo_name}/issues/1/comments","Issue does not exist")

    assert_equal(0,response_body.length,"Comment not deleted")
  end

  def teardown
    delete_repo(@repo_name)
    delete_token
  end
end
