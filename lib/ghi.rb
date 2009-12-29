require "net/http"
require "yaml"

module GHI
  VERSION = "0.2.4"

  class << self
    def login
      return @login if defined? @login
      @login = `git config --get github.user`.chomp
      if @login.empty?
        begin
          print "Please enter your GitHub username: "
          @login = gets.chomp
          valid = user? @login
          warn "invalid username" unless valid
        end until valid
        `git config --global github.user #@login`
      end
      @login
    end

    def token
      return @token if defined? @token
      @token = `git config --get github.token`.chomp
      if @token.empty?
        begin
          print "GitHub token (https://github.com/account): "
          @token = gets.chomp
          valid = token? @token
          warn "invalid token for #{login}" unless valid
        end until valid
        `git config --global github.token #@token`
      end
      @token
    end

    private

    def user?(username)
      url = "http://github.com/api/v2/yaml/user/show/#{username}"
      !YAML.load(Net::HTTP.get(URI.parse(url)))["user"].nil?
    rescue ArgumentError, URI::InvalidURIError
      false
    end

    def token?(token)
      url  = "http://github.com/api/v2/yaml/user/show/#{login}"
      url += "?login=#{login}&token=#{token}"
      !YAML.load(Net::HTTP.get(URI.parse(url)))["user"]["plan"].nil?
    rescue ArgumentError, NoMethodError, URI::InvalidURIError
      false
    end
  end
end
