require "net/http"
require "yaml"

class GHI::API
  class InvalidConnection < StandardError
  end

  class ResponseError < StandardError
  end

  API_URL = "http://github.com/api/v2/yaml/issues/:action/:user/:repo"

  attr_reader :user, :repo

  def initialize(user, repo)
    raise InvalidConnection if user.nil? || repo.nil?
    @user, @repo = user, repo
  end

  def list(state = :open)
    res = get :list, state
    raise ResponseError, res if res["issues"].nil?
    res["issues"].map { |attrs| GHI::Issue.new(attrs) }
  end

  def show(number)
    res = get :show, number
    raise ResponseError, res if res["issue"].nil?
    GHI::Issue.new res["issue"]
  end

  def open(title, body)
    res = post(:open, :title => title, :body => body)
    raise ResponseError, res if res["issue"].nil?
    GHI::Issue.new res["issue"]
  end

  def edit(number, title, body)
    res = post(:edit, number, :title => title, :body => body)
    raise ResponseError, res if res["issue"].nil?
    GHI::Issue.new res["issue"]
  end

  def close(number)
    res = post :close, number
    raise ResponseError, res if res["issue"].nil?
    GHI::Issue.new res["issue"]
  end

  def reopen(number)
    res = post :reopen, number
    raise ResponseError, res if res["issue"].nil?
    GHI::Issue.new res["issue"]
  end

  private

  def get(*args)
    res = Net::HTTP.get URI.parse(url(*args) + auth(true))
    YAML.load res
  end

  def post(*args)
    params = args.last.is_a?(Hash) ? args.pop : {}
    params.update auth
    res = Net::HTTP.post_form URI.parse(url(*args)), params
    YAML.load res.body
  end

  def auth(query = false)
    if query
      "?login=#{GHI.login}&token=#{GHI.token}"
    else
      { :login => GHI.login, :token => GHI.token }
    end
  end

  def url(action, option = nil)
    @url ||= API_URL.sub(":user", user).sub(":repo", repo)
    uri  = @url.sub ":action", action.to_s
    uri += "/#{option}" unless option.nil?
    uri
  end
end
