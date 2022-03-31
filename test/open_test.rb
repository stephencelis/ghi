require "test/unit"
require "helper"
require "pp"

class Test_open < Test::Unit::TestCase
  def setup
    gen_token
    @repo_name=create_repo
  end

  def test_open_issue
    open_issue @repo_name
  end

  def teardown
    delete_repo(@repo_name)
    delete_token
  end

end
