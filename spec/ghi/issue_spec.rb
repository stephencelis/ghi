require "ghi"
require "ghi/issue"

describe GHI::Issue do
  before :each do
    @now = Time.now
    @issue = GHI::Issue.new "number"     => 1,
                            "state"      => "open",
                            "title"      => "new issue",
                            "user"       => "schacon",
                            "votes"      => 0,
                            "created_at" => @now,
                            "updated_at" => @now,
                            "body"       => "my sweet, sweet issue"
  end

  it "should read all keys" do
    @issue.number.should == 1
    @issue.state.should == "open"
    @issue.title.should == "new issue"
    @issue.user.should == "schacon"
    @issue.votes.should == 0
    @issue.created_at.should == @now
    @issue.updated_at.should == @now
  end
end
