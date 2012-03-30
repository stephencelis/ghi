module GHI
  module Version
    MAJOR   = 1
    MINOR   = 0
    PATCH   = 0
    PRE     = 'dev'

    VERSION = [MAJOR, MINOR, PATCH, PRE].compact.join '.'

    def self.execute args
      puts "ghi version #{VERSION}"
    end
  end
end
