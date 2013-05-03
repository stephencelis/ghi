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
      launcher = 'open'
      launcher = 'xdg-open' if /linux/ =~ RUBY_PLATFORM
      system "#{launcher} '#{uri_for path, params}'"
    end

    def curl path = '', params = {}
      uri_for(path, params).open.read
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
