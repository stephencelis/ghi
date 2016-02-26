module GHI
  module Commands
    module Version
      MAJOR   = 1
      MINOR   = 1
      PATCH   = 1
      PRE     = nil

      VERSION = [MAJOR, MINOR, PATCH, PRE].compact.join '.'

      def self.execute args
        puts "ghi version #{VERSION}"
      end
    end
  end
end
