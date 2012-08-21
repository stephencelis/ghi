require 'open-uri'
require 'uri'

module GHI
  class Web
    BASE_URI = 'https://github.com/'

    attr_reader :base
    def initialize base
      @base = base
    end

    def open path = '', params = {}
      system "open '#{uri_for path, params}'"
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
