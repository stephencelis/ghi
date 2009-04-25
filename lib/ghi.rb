module GHI
  VERSION = "0.0.4"

  def self.login
    return @login if defined? @login
    @login = `git config --get github.user`.chomp
    if @login.empty?
      print "Please enter your GitHub username: "
      @login = gets
      `git config --global github.user #@login`
    end
    @login
  end

  def self.token
    return @token if defined? @token
    @token = `git config --get github.token`.chomp
    if @token.empty?
      print "GitHub token (https://github.com/account): "
      @token = gets
      `git config --global github.token #@token`
    end
    @token
  end
end
