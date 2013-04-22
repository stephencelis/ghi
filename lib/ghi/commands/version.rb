module GHI
  module Commands
    module Version
      MAJOR   = 0
      MINOR   = 9
      PATCH   = 0
      PRE     = 20130422.1

      VERSION = [MAJOR, MINOR, PATCH, PRE].compact.join '.'

      def self.execute args
        puts "ghi version #{VERSION}"
      end
    end
  end
end
