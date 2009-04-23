module GHI
  VERSION = "0.0.2"

  def self.login
    `git config --get github.user`.chomp
  end

  def self.token
    `git config --get github.token`.chomp
  end
end
