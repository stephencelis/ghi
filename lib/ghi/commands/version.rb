require 'net/http'
require 'json'

module GHI
  module Commands
    module Version

      def self.execute args
        puts "ghi version #{get_latest_version}"
      end

      def self.get_latest_version
        result = JSON.parse(Net::HTTP.get(URI.parse('https://api.github.com/repos/stephencelis/ghi/releases/latest')))
        return result['tag_name'] 
      end      

    end
  end
end
