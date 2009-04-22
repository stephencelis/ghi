$: << File.expand_path(File.dirname(__FILE__) + "/../lib")
require "ghi"

describe GHI do
  it "should return login" do
    GHI.stub!(:`).and_return "stephencelis\n"
    GHI.login.should == "stephencelis"
  end
  
  it "should return token" do
    GHI.stub!(:`).and_return "da39a3ee5e6b4b0d3255bfef95601890\n"
    GHI.token.should == "da39a3ee5e6b4b0d3255bfef95601890"
  end
end
