require "net/http"
require "yaml"

class GHI::API
  class InvalidRequest < StandardError
  end

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

  def search(term, state = :open)
    get(:search, state, term)["issues"].map { |attrs| GHI::Issue.new(attrs) }
  end

  def list(state = :open)
    get(:list, state)["issues"].map { |attrs| GHI::Issue.new(attrs) }
  end

  def show(number)
    GHI::Issue.new get(:show, number)["issue"]
  end

  def open(title, body)
    GHI::Issue.new post(:open, "title" => title, "body" => body)["issue"]
  end

  def edit(number, title, body)
    res = post :edit, number, "title" => title, "body" => body
    GHI::Issue.new res["issue"]
  end

  def close(number)
    GHI::Issue.new post(:close, number)["issue"]
  end

  def reopen(number)
    GHI::Issue.new post(:reopen, number)["issue"]
  end

  def add_label(label, number)
    post("label/add", label, number)["labels"]
  end

  def remove_label(label, number)
    post("label/remove", label, number)["labels"]
  end

  def comment(number, comment)
    post(:comment, number, "comment" => comment)["comment"]
  end

  private

  def get(*args)
    res = YAML.load Net::HTTP.get(URI.parse(url(*args) + auth(true)))
    raise ResponseError, errors(res) if res["error"]
    res
  rescue ArgumentError, URI::InvalidURIError
    raise ResponseError, "GitHub hiccuped on your request"
  rescue SocketError
    raise ResponseError, "couldn't find the internet"
  end

  def post(*args)
    params = args.last.is_a?(Hash) ? args.pop : {}
    params.update auth
    res = YAML.load Net::HTTP.post_form(URI.parse(url(*args)), params).body
    raise ResponseError, errors(res) if res["error"]
    res
  rescue ArgumentError, URI::InvalidURIError
    raise ResponseError, "GitHub hiccuped on your request"
  rescue SocketError
    raise ResponseError, "couldn't find the internet"
  end

  def errors(response)
    [*response["error"]].map { |e| e["error"] } * ", "
  end

  def auth(query = false)
    if query
      "?login=#{GHI.login}&token=#{GHI.token}"
    else
      { "login" => GHI.login, "token" => GHI.token }
    end
  end

  def url(action, *args)
    @url ||= API_URL.sub(":user", user).sub(":repo", repo)
    uri  = @url.sub ":action", action.to_s
    uri += "/#{args.join("/")}" unless args.empty?
    uri
  end
end
