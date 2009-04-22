$: << File.expand_path(File.dirname(__FILE__) + "/../lib")
require "ghi"
require "ghi/api"
include GHI

describe GHI::API do
  it "should require user and repo" do
    proc { API.new(nil, nil) }.should raise_error(API::InvalidConnection)
    proc { API.new("u", nil) }.should raise_error(API::InvalidConnection)
    proc { API.new(nil, "r") }.should raise_error(API::InvalidConnection)
    proc { API.new("u", "r") }.should_not raise_error(API::InvalidConnection)
  end
end
