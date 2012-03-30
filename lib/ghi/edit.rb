module GHI
  class Edit
    def self.options
      OptionParser.new do |opts|
        opts.banner = 'usage: ghi edit <issueno>'
        opts.separator ''
      end
    end

    def self.execute args
      options.parse! args
    end
  end
end
