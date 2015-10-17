module GHI
  module Commands
    module Version
      MAJOR   = 1
      MINOR   = 0
      PATCH   = 2
      PRE     = nil

      VERSION = [MAJOR, MINOR, PATCH, PRE].compact.join '.'

      def self.execute args
        puts "ghi version #{VERSION}"
      end
    end
  end
end
