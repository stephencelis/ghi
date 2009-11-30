require "ghi"
require "ghi/api"
require "ghi/cli"

describe GHI::CLI::Executable do
  before :each do
    @cli = GHI::CLI::Executable.new
    @cli.stub!(:api).and_return(mock(GHI::API))
    $stdout.stub! :close_write
    IO.stub!(:popen).and_return $stdout
  end

  describe "parsing" do
    describe "with well-formed arguments" do
      before :each do
        @user, @repo = "local_user_host", "ghi"
        @action = @state = @number = @term =
          @title = @body = @tag = @comment = nil
      end

      after :each do
        @cli.should_receive(@action)
        @cli.parse! Array(@args)
        @cli.action.should == @action
        @cli.state.should  == (@state || :open)
        @cli.number.should == @number
        @cli.search_term.should == @term
        @cli.title.should == @title
        @cli.body.should == @body
        @cli.user.should == @user
        @cli.repo.should == @repo
        @cli.tag.should == @tag
        if @commenting
          @cli.should be_commenting
        else
          @cli.should_not be_commenting
        end
      end

      it "should always parse -r" do
        @args = ["-rremoteuser/remoterepo", "-l"]
        @action, @state, @user, @repo = :list, :open, "remoteuser", "remoterepo"
      end

      describe "inside a repository" do
        after :each do
          @cli.stub!(:`).and_return "stub@github.com:#@user/#@repo.git"
        end

        it "should parse empty as list open" do
          @action, @state = :list, :open
        end

        it "should parse -l as list open" do
          @args = ["-l"]
          @action, @state = :list, :open
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
          @action, @state, @term = :search, :open, "term"
        end

        it "should parse -o as open new issue" do
          @args = ["-o"]
          @action = :open
        end

        it "should parse -o 'New Issue' as open issue with title 'New Issue'" do
          @args = ["-o", "New Issue"]
          @action, @title = :open, "New Issue"
        end

        it "should parse -om 'New Issue' as open issue with'New Issue'" do
          @args = ["-om", "New Issue"]
          @action, @title = :open, "New Issue"
        end

        it "should parse -o 'New Issue' -m as open 'New Issue' in $EDITOR" do
          @args = ["-o", "New Issue", "-m"]
          @action, @title, @commenting = :open, "New Issue", true
        end

        it "should parse -o 'Issue' -m 'Body' as open 'Issue' with 'Body'" do
          @args = ["-o", "Issue", "-m", "Body"]
          @action, @title, @body = :open, "Issue", "Body"
        end

        it "should parse -o2 as reopen issue 2" do
          @args = ["-o2"]
          @action, @number = :reopen, 2
        end

        it "should parse -o2 -m as reopen issue 2 with a comment" do
          @args = ["-o2", "-m"]
          @action, @number, @commenting = :reopen, 2, true
        end

        it "should parse -o2 -m 'Comment' as reopen issue 2" do
          @args = ["-o2", "-m", "Comment"]
          @action, @number, @body = :reopen, 2, "Comment"
        end

        it "should parse -ol as list open" do
          @args = ["-ol"]
          @action, @state = :list, :open
        end

        it "should parse -ou as return open issues url" do
          @args = ["-ou"]
          @action = :url # Should state be :open?
        end

        it "should parse -cl as list closed" do
          @args = ["-cl"]
          @action, @state = :list, :closed
        end

        it "should parse -c2 as close issue 2" do
          @args = ["-c2"]
          @action, @number = :close, 2
        end

        it "should parse -c2 -m as close issue 2 with a comment" do
          @args = ["-c2", "-m"]
          @action, @number, @commenting = :close, 2, true
        end

        it "should parse -c2 -m 'Fixed' as close issue 2 with 'Fixed'" do
          @args = ["-c2", "-m", "Fixed"]
          @action, @number, @body = :close, 2, "Fixed"
        end

        it "should parse -m2 -c as close issue 2 with a comment" do
          @args = ["-m2", "-c"]
          @action, @number, @commenting = :close, 2, true
        end

        it "should parse -cu as return closed issues url" do
          @args = ["-cu"]
          @action, @state = :url, :closed
        end

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

        it "should parse -rremoteuser/remoterepo as a later argument" do
          @args = ["-1", "-rremoteuser/remoterepo"]
          @action, @number, @user, @repo = :show, 1, "remoteuser", "remoterepo"
        end

        it "should parse -t2 'tag' as label issue 2 with 'tag'" do
          @args = ["-t2", "tag"]
          @action, @number, @tag = :label, 2, "tag"
        end

        it "should parse -d2 'tag' as remove label 'tag' from issue 2" do
          @args = ["-d2", "tag"]
          @action, @number, @tag = :unlabel, 2, "tag"
        end

        it "should parse -m2 as comment on issue 2" do
          @args = ["-m2"]
          @action, @number, @commenting = :comment, 2, true
        end

        it "should parse -m2 'Comment' as comment 'Comment' on issue 2" do
          @args = ["-m2", "Comment"]
          @action, @number, @body = :comment, 2, "Comment"
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

        it "should parse -uu as return unread issues url" do
          @args = ["-uu"]
          @action, @state = :url, :unread
        end
      end
    end

    describe "with malformed arguments" do
      before :each do
        @cli.should_receive :warn
        @cli.should_receive(:exit).with 1
      end

      it "should exit with -e" do
        @cli.should_receive :puts
        @cli.parse! ["-e"]
      end

      it "should exit with -e 'invalid'" do
        @cli.should_receive :puts
        @cli.parse! ["-e", "invalid"]
      end

      it "should exit with -c as list closed" do
        @cli.parse! ["-c"]
      end

      it "should exit with -r" do
        @cli.should_receive :puts
        @cli.parse! ["-r"]
      end

      it "should exit with -t" do
        @cli.should_receive :puts
        @cli.parse! ["-t"]
      end

      it "should exit with -t2" do
        @cli.parse! ["-t2"]
      end
    end
  end
end
