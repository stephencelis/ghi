require "net/http"
require "yaml"
YAML::ENGINE.yamler = "syck" if YAML.const_defined? :ENGINE

module GHI
  VERSION = "0.3.0"

  class << self
    def login
      return @login if defined? @login
      @login = ENV["GITHUB_USER"] || `git config --get github.user`.chomp
      if @login.empty?
        warn "Please configure your GitHub username."
        puts
        puts "E.g., git config --global github.user [your username]"
        puts "Or set the environment variable GITHUB_USER"
        abort
      end
      @login
    end

    def token
      return @token if defined? @token
      # env values are frozen
      @token = (ENV["GITHUB_TOKEN"] || `git config --get github.token`.chomp).dup
      if @token.empty?
        warn "Please configure your GitHub token."
        puts
        puts "E.g., git config --global github.token [your token]"
        puts "Or set the environment variable GITHUB_TOKEN"
        puts
        puts "Find your token here: https://github.com/account/admin"
        abort
      elsif @token.sub!(/^!/, '')
        @token = `#@token`
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
