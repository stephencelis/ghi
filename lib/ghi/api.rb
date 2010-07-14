require "net/http"
require "yaml"
require "cgi"

class GHI::API
  class InvalidRequest < StandardError
  end

  class InvalidConnection < StandardError
  end

  class ResponseError < StandardError
  end

  API_HOST  = "github.com"
  API_PATH  = "/api/v2/yaml/issues/:action/:user/:repo"

  attr_reader :user, :repo

  def initialize(user, repo, use_ssl = false)
    raise InvalidConnection if user.nil? || repo.nil?
    @user, @repo, @use_ssl = user, repo, use_ssl
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
    res = nil
    http = Net::HTTP.new(API_HOST, @use_ssl ? 443 : 80)
    http.use_ssl = true if @use_ssl
    http.start do
      if @use_ssl
        req = Net::HTTP::Post.new path(*args)
        req.set_form_data auth
      else
        req = Net::HTTP::Get.new(path(*args) + auth(true))
      end
      res = YAML.load http.request(req).body
    end

    raise ResponseError, errors(res) if res["error"]
    res
  rescue ArgumentError, URI::InvalidURIError
    raise ResponseError, "GitHub hiccuped on your request"
  rescue SocketError
    raise ResponseError, "couldn't find the internet"
  end

  def post(*args)
    params = args.last.is_a?(Hash) ? args.pop : {}

    res = nil
    http = Net::HTTP.new(API_HOST, @use_ssl ? 443 : 80)
    http.use_ssl = true if @use_ssl
    http.start do
      req = Net::HTTP::Post.new path(*args)
      req.set_form_data params.merge(auth)
      res = YAML.load http.request(req).body
    end

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

  def path(action, *args)
    @path ||= API_PATH.sub(":user", user).sub(":repo", repo)
    path  = @path.sub ":action", action.to_s
    path << "/#{args.join("/")}" unless args.empty?
    path
  end
end
