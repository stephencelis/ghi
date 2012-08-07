require 'cgi'
require 'net/https'

unless defined? Net::HTTP::Patch
  # PATCH support for 1.8.7.
  Net::HTTP::Patch = Class.new(Net::HTTP::Post) { METHOD = 'PATCH' }
end

module GHI
  class Client
    autoload :JSON, 'ghi/json'

    class Error < RuntimeError
      attr_reader :response
      def initialize response
        @response, @json = response, JSON.parse(response.body)
      end

      def body()    @json             end
      def message() body['message']   end
      def errors()  [*body['errors']] end
    end

    class Response
      def initialize response
        @response = response
      end

      def body
        @body ||= JSON.parse @response.body
      end

      def next_page() links['next'] end
      def last_page() links['last'] end

      private

      def links
        return @links if defined? @links
        @links = {}
        if links = @response['Link']
          links.scan(/<([^>]+)>; rel="([^"]+)"/).each { |l, r| @links[r] = l }
        end
        @links
      end
    end

    CONTENT_TYPE = 'application/vnd.github+json'
    METHODS = {
      :head   => Net::HTTP::Head,
      :get    => Net::HTTP::Get,
      :post   => Net::HTTP::Post,
      :put    => Net::HTTP::Put,
      :patch  => Net::HTTP::Patch,
      :delete => Net::HTTP::Delete
    }

    attr_reader :username, :password
    def initialize username = nil, password = nil
      @username, @password = username, password
    end

    def head path, options = {}
      request :head, path, options
    end

    def get path, params = {}, options = {}
      request :get, path, options.merge(:params => params)
    end

    def post path, body = nil, options = {}
      request :post, path, options.merge(:body => body)
    end

    def put path, body = nil, options = {}
      request :put, path, options.merge(:body => body)
    end

    def patch path, body = nil, options = {}
      request :patch, path, options.merge(:body => body)
    end

    def delete path, options = {}
      request :delete, path, options
    end

    private

    def request method, path, options
      if params = options[:params] and !params.empty?
        q = params.map { |k, v| "#{CGI.escape k.to_s}=#{CGI.escape v.to_s}" }
        path += "?#{q.join '&'}"
      end

      req = METHODS[method].new path, 'Accept' => CONTENT_TYPE
      if GHI::Authorization.token
        req['Authorization'] = "token #{GHI::Authorization.token}"
      end
      if options.key? :body
        req['Content-Type'] = CONTENT_TYPE
        req.body = options[:body] ? JSON.dump(options[:body]) : ''
      end
      req.basic_auth username, password if username && password

      proxy = ENV['https_proxy'] || ENV['http_proxy']
      if proxy
        http = Net::HTTP::Proxy(URI.parse(proxy).host, URI.parse(proxy).port).new 'api.github.com', 443
      else
        http = Net::HTTP.new 'api.github.com', 443
      end

      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # FIXME 1.8.7

      GHI.v? and puts "\r===> #{method.to_s.upcase} #{path} #{req.body}"
      res = http.start { http.request req }
      GHI.v? and puts "\r<=== #{res.code}: #{res.body}"

      case res
      when Net::HTTPSuccess
        return Response.new(res)
      when Net::HTTPUnauthorized
        if password.nil?
          raise Authorization::Required, 'Authorization required'
        end
      end

      raise Error, res
    end
  end
end
