require "ghi"
require "ghi/cli"

describe GHI::CLI::Executable do
  describe "parsing" do
    describe "with well-formed arguments" do
      before :each do
        @user, @repo = "localuser", "ghi"
        @cli = @action = @state = @number = @search_term = @title = @body =
          @tag = nil
      end

      after :each do
        @cli = GHI::CLI::Executable.new(@args)
        @cli.stub!(:`).and_return "stub:localuser/ghi.git"
        @cli.should_receive(@action)
        @cli.run!
        @cli.action.should == @action
        @cli.state.should  == @state
        @cli.number.should == @number
        @cli.search_term.should == @search_term
        @cli.title.should == @title
        @cli.body.should == @body
        @cli.user.should == @user
        @cli.repo.should == @repo
        @cli.tag.should == @tag
      end

      it "should parse -l as list open" do
        @args = ["-l"]
        @action, @state = :list, :open
      end

      it "should parse -lo as list open" do
        @args = ["-lo"]
        @action, @state = :list, :open
      end

      it "should parse -lc as list closed" do
        @args = ["-lc"]
        @action, @state = :list, :closed
      end

      it "should parse -l2 as show issue 2" do
        @args = ["-l2"]
        @action, @number = :show, 2
      end

      it "should parse -l 'term' as search open for 'term'" do
        @args = ["-l", "term"]
        @action, @state, @search_term = :search, :open, "term"
      end

      it "should parse -o as open new issue" do
        @args = ["-o"]
        @action = :open
      end

      it "should parse -o 'New Issue' as open issue with title 'New Issue'" do
        @args = ["-o", "New Issue"]
        @action, @title = :open, "New Issue"
      end

      it "should parse -o2 as reopen issue 2" do
        @args = ["-o2"]
        @action, @number = :reopen, 2
      end

      it "should parse -ol as list open" do
        @args = ["-ol"]
        @action, @state = :list, :open
      end

      it "should parse -ou as return open issues url" do
        @args = ["-ou"]
        @action = :url # Should state be :open?
      end

      it "should parse -c as list closed" do
        @args = ["-c"]
        @action, @state = :list, :closed
      end

      it "should parse -cl as list closed" do
        @args = ["-cl"]
        @action, @state = :list, :closed
      end

      it "should parse -c2 as close issue 2" do
        @args = ["-c2"]
        @action, @number = :close, 2
      end

      it "should parse -c2 -m as close issue 2 with a comment"
      it "should parse -m2 -c as close issue 2 with a comment"

      it "should parse -cu as return closed issues url" do
        @args = ["-cu"]
        @action, @state = :url, :closed
      end

      it "should parse -uu as return unread issues url"

      it "should parse -e2 as edit issue 2" do
        @args = ["-e2"]
        @action, @number = :edit, 2
      end

      it "should parse -rlocalrepo as localuser/localrepo" do
        GHI.stub!(:login).and_return "localuser"
        @args = ["-rlocalrepo", "-l"]
        @action, @state, @user, @repo = :list, :open, "localuser", "localrepo"
      end

      it "should parse -rremoteuser/remoterepo as remoteuser/remoterepo" do
        @args = ["-rremoteuser/remoterepo", "-l"]
        @action, @state, @user, @repo = :list, :open, "remoteuser", "remoterepo"
      end

      it "should parse -m to note editor use" # do
      #   @args = ["-m"]
      # end
      
      it "should parse -m 'message' to bypass editor use" # do
      #   @args = ["-m", "message"]
      # end

      it "should parse -t2 'tag' as label issue 2 with 'tag'" do
        @args = ["-t2", "tag"]
        @action, @number, @tag = :label, 2, "tag"
      end

      it "should parse -d2 'tag' as remove label 'tag' from issue 2" do
        @args = ["-d2", "tag"]
        @action, @number, @tag = :unlabel, 2, "tag"
      end

      it "should parse -u as return open issues url" do
        @args = ["-u"]
        @action = :url # Should state be :open?
      end

      it "should parse -uo as return open issues url" do
        @args = ["-uo"]
        @action = :url # Should state be :open?
      end

      it "should parse -uc as return open issues url" do
        @args = ["-uc"]
        @action, @state = :url, :closed
      end

      it "should parse -u2 as return issue 2 url" do
        @args = ["-u2"]
        @action, @number = :url, 2
      end
    end

    describe "with malformed arguments" do
      it "should raise an exception with -e" do
        proc { GHI::CLI::Executable.new(["-e"]) }.should \
          raise_error(OptionParser::MissingArgument)
      end

      it "should raise an exception with -e 'invalid'" do
        proc { GHI::CLI::Executable.new(["-e 'invalid'"]) }.should \
          raise_error(OptionParser::InvalidOption)
      end

      it "should raise an exception with -r" do
        proc { GHI::CLI::Executable.new(["-r"]) }.should \
          raise_error(OptionParser::MissingArgument)
      end

      it "should raise an exception with -t" do
        proc { GHI::CLI::Executable.new(["-t"]) }.should \
          raise_error(OptionParser::MissingArgument)
      end

      it "should raise an exception with -t2" # do
      #   proc { GHI::CLI::Executable.new(["-t2"]) }.should \
      #     raise_error(OptionParser::InvalidOption)
      # end
    end
  end
end
