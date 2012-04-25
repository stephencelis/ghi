require 'uri'

module GHI
  class Web
    BASE_URI = 'https://github.com/'

    attr_reader :base
    def initialize base
      @base = base
    end

    def open path = '', params = {}
      unless params.empty?
        q = params.map { |k, v| "#{CGI.escape k.to_s}=#{CGI.escape v.to_s}" }
        path += "?#{q.join '&'}"
      end
      system "open '#{uri + path}'"
    end

    private

    def uri
      URI(BASE_URI) + "#{base}/"
    end
  end
end
