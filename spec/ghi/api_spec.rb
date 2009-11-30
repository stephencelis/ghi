$: << File.expand_path(File.dirname(__FILE__) + "/../lib")
require "ghi"
require "ghi/api"
require "ghi/issue"
include GHI

ISSUES_YAML = <<-YAML
---
issues:
- number: 1
  votes: 0
  created_at: 2009-04-17 14:55:33 -07:00
  body: my sweet, sweet issue
  title: new issue
  updated_at: 2009-04-17 14:55:33 -07:00
  user: schacon
  state: open
- number: 2
  votes: 0
  created_at: 2009-04-17 15:16:47 -07:00
  body: the body of a second issue
  title: another issue
  updated_at: 2009-04-17 15:16:47 -07:00
  user: schacon
  state: open
YAML

ISSUE_YAML = <<-YAML
---
issue:
  number: 1
  votes: 0
  created_at: 2009-04-17 14:55:33 -07:00
  body: my sweet, sweet issue
  title: new issue
  updated_at: 2009-04-17 14:55:33 -07:00
  user: schacon
  state: open
YAML

LABELS_YAML = <<-YAML
---
labels:
- testing
- test_label
YAML

COMMENT_YAML = <<-YAML
---
comment:
  comment: this is amazing
  status: saved
YAML

describe GHI::API do
  it "should require user and repo" do
    proc { API.new(nil, nil) }.should raise_error(API::InvalidConnection)
    proc { API.new("u", nil) }.should raise_error(API::InvalidConnection)
    proc { API.new(nil, "r") }.should raise_error(API::InvalidConnection)
    proc { API.new("u", "r") }.should_not raise_error(API::InvalidConnection)
  end

  describe "requests" do
    before :each do
      @api = API.new "stephencelis", "ghi"
      GHI.stub!(:login).and_return "stephencelis"
      GHI.stub!(:token).and_return "token"
    end

    it "should substitute url tokens" do
      @api.send(:url, :open).should ==
        "http://github.com/api/v2/yaml/issues/open/stephencelis/ghi"
      @api.send(:url, :show, 1).should ==
        "http://github.com/api/v2/yaml/issues/show/stephencelis/ghi/1"
      @api.send(:url, :search, :open, "me").should ==
        "http://github.com/api/v2/yaml/issues/search/stephencelis/ghi/open/me"
      @api.send(:url, "label/add", "me").should ==
        "http://github.com/api/v2/yaml/issues/label/add/stephencelis/ghi/me"
    end

    it "should process gets" do
      url   = "http://github.com/api/v2/yaml/issues/open/stephencelis/ghi"
      query = "?login=stephencelis&token=token"
      @api.stub!(:url).and_return url
      URI.should_receive(:parse).once.with(url + query).and_return("mock")
      Net::HTTP.should_receive(:get).once.with("mock").and_return ISSUES_YAML
      @api.list
    end

    it "should process posts" do
      url   = "http://github.com/api/v2/yaml/issues/open/stephencelis/ghi"
      query = { "login" => "stephencelis",
                "token" => "token",
                "title" => "Title",
                "body"  => "Body" }
      @api.stub!(:url).and_return url
      r = mock(Net::HTTPRequest)
      r.should_receive(:body).once.and_return ISSUE_YAML
      URI.should_receive(:parse).once.with(url).and_return "u"
      Net::HTTP.should_receive(:post_form).once.with("u", query).and_return r
      @api.open "Title", "Body"
    end

    it "should search open by default" do
      @api.should_receive(:url).with(:search, :open, "me").and_return "u"
      Net::HTTP.stub!(:get).and_return ISSUES_YAML
      issues = @api.search "me"
      issues.should be_an_instance_of(Array)
      issues.each { |issue| issue.should be_an_instance_of(Issue) }
    end

    it "should search closed" do
      @api.should_receive(:url).with(:search, :closed, "me").and_return "u"
      Net::HTTP.stub!(:get).and_return ISSUES_YAML
      @api.search "me", :closed
    end

    it "should list open by default" do
      @api.should_receive(:url).with(:list, :open).and_return "u"
      Net::HTTP.stub!(:get).and_return ISSUES_YAML
      issues = @api.list
      issues.should be_an_instance_of(Array)
      issues.each { |issue| issue.should be_an_instance_of(Issue) }
    end

    it "should list closed" do
      @api.should_receive(:url).with(:list, :closed).and_return "u"
      Net::HTTP.stub!(:get).and_return ISSUES_YAML
      @api.list :closed
    end

    it "should show" do
      @api.should_receive(:url).with(:show, 1).and_return "u"
      Net::HTTP.stub!(:get).and_return ISSUE_YAML
      @api.show(1).should be_an_instance_of(Issue)
    end

    it "should open" do
      @api.should_receive(:url).with(:open).and_return "u"
      response = mock(Net::HTTPRequest)
      response.stub!(:body).and_return ISSUE_YAML
      Net::HTTP.stub!(:post_form).and_return response
      @api.open("Title", "Body").should be_an_instance_of(Issue)
    end

    it "should edit" do
      @api.should_receive(:url).with(:edit, 1).and_return "u"
      response = mock(Net::HTTPRequest)
      response.stub!(:body).and_return ISSUE_YAML
      Net::HTTP.stub!(:post_form).and_return response
      @api.edit(1, "Title", "Body").should be_an_instance_of(Issue)
    end

    it "should close" do
      @api.should_receive(:url).with(:close, 1).and_return "u"
      response = mock(Net::HTTPRequest)
      response.stub!(:body).and_return ISSUE_YAML
      Net::HTTP.stub!(:post_form).and_return response
      @api.close(1).should be_an_instance_of(Issue)
    end

    it "should reopen" do
      @api.should_receive(:url).with(:reopen, 1).and_return "u"
      response = mock(Net::HTTPRequest)
      response.stub!(:body).and_return ISSUE_YAML
      Net::HTTP.stub!(:post_form).and_return response
      @api.reopen(1).should be_an_instance_of(Issue)
    end

    it "should add labels" do
      @api.should_receive(:url).with("label/add", 1, "l").and_return "u"
      response = mock(Net::HTTPRequest)
      response.stub!(:body).and_return LABELS_YAML
      Net::HTTP.stub!(:post_form).and_return response
      @api.add_label(1, "l").should be_an_instance_of(Array)
    end

    it "should remove labels" do
      @api.should_receive(:url).with("label/remove", 1, "l").and_return "u"
      response = mock(Net::HTTPRequest)
      response.stub!(:body).and_return LABELS_YAML
      Net::HTTP.stub!(:post_form).and_return response
      @api.remove_label(1, "l").should be_an_instance_of(Array)
    end

    it "should comment" do
      @api.should_receive(:url).with(:comment, 1).and_return "u"
      URI.stub!(:parse).and_return "u"
      response = mock(Net::HTTPRequest)
      response.stub!(:body).and_return COMMENT_YAML
      Net::HTTP.should_receive(:post_form).with("u",
        hash_including("comment" => "Comment")).and_return response
      @api.comment(1, "Comment").should be_an_instance_of(Hash)
    end
  end
end
