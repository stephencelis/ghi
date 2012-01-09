require "ghi"

LOGGED_OUT_YAML = <<-YAML
---
user:
  id: 23
  login: defunkt
  name: Kristopher Walken Wanstrath
  company: LA
  location: SF
  email: me@email.com
  blog: http://myblog.com
  following_count: 13
  followers_count: 63
  public_gist_count: 0
  public_repo_count: 2
YAML

LOGGED_IN_YAML = <<-YAML
---
user:
  id: 23
  login: defunkt
  name: Kristopher Walken Wanstrath
  company: LA
  location: SF
  email: me@email.com
  blog: http://myblog.com
  following_count: 13
  followers_count: 63
  public_gist_count: 0
  public_repo_count: 2
  total_private_repo_count: 1
  collaborators: 3
  disk_usage: 50384
  owned_private_repo_count: 1
  private_gist_count: 0
  plan:
    name: mega
    collaborators: 60
    space: 20971520
    private_repos: 125
YAML

describe GHI do
  before :each do
    GHI.instance_eval do
      remove_instance_variable :@login if instance_variable_defined? :@login
      remove_instance_variable :@token if instance_variable_defined? :@token
    end
  end

  it "should return login" do
    GHI.should_receive(:`).once.and_return "stephencelis\n"
    GHI.login.should == "stephencelis"
  end

  it "should return token" do
    GHI.should_receive(:`).once.and_return "da39a3ee5e6b4b0d3255bfef95601890\n"
    GHI.token.should == "da39a3ee5e6b4b0d3255bfef95601890"
  end
end
