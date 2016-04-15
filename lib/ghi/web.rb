require 'open-uri'
require 'uri'

module GHI
  class Web
    HOST = GHI.config('github.host') || 'github.com'
    BASE_URI = "https://#{HOST}/"

    attr_reader :base
    def initialize base
      @base = base
    end

    def open path = '', params = {}
      path = uri_for path, params
      $stdout.puts path
      return unless $stdout.tty?
      launcher = 'open'
      launcher = 'xdg-open' if /linux/ =~ RUBY_PLATFORM
      system "#{launcher} '#{path}'"
    end

    def curl path = '', params = {}
      proxy_uri   = GHI.config 'https.proxy', :upcase => false
      proxy_uri ||= GHI.config 'http.proxy',  :upcase => false
      proxy = URI.parse proxy_uri
      if !(proxy.user.nil? || proxy.password.nil?)
        uri_for(path, params).open(:proxy_http_basic_authentication => [proxy_uri, proxy.user, proxy.password]).read
      else
        uri_for(path, params).open.read
      end
    end

    private

    def uri_for path, params
      unless params.empty?
        q = params.map { |k, v| "#{CGI.escape k.to_s}=#{CGI.escape v.to_s}" }
        path += "?#{q.join '&'}"
      end
      URI(BASE_URI) + "#{base}/" + path
    end
  end
end
