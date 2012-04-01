require 'net/http'

module GHI
  class Client
    autoload :JSON, 'ghi/json'

    class Error < RuntimeError
      attr_reader :response
      def initialize response
        @response = response
        @json = JSON.parse response.body
      end

      def message
        @json['message']
      end

      def errors
        [*@json['errors']]
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
      if options[:params] && !options[:params].empty?
        path += "?#{URI.encode_www_form options[:params]}"
      end

      req = METHODS[method].new path, 'Accept' => CONTENT_TYPE
      if GHI::Authorization.token
        req['Authorization'] = "token #{GHI::Authorization.token}"
      end
      if options.key? :body
        req['Content-Type'] = CONTENT_TYPE
        req.body = options[:body] ? JSON.dump(options[:body]) : ''
      end
      req.basic_auth username, password if username || password

      http = Net::HTTP.new 'api.github.com', 443
      http.use_ssl = true

      GHI.v? and puts "===> #{method.to_s.upcase} #{path} #{req.body}"
      res = http.start { http.request req }
      GHI.v? and puts "<=== #{res.code}: #{res.body}"

      case res
      when Net::HTTPSuccess
        JSON.parse res.body if res.body
      when Net::HTTPUnauthorized
        raise Authorization::Required, 'Authorization required'
      else
        raise Error, res
      end
    end
  end
end
