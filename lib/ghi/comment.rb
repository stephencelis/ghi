module GHI
  class Comment
    def self.options
      OptionParser.new do |opts|
        opts.banner = 'usage: ghi comment <issueno>'
        opts.separator ''
      end
    end

    def self.execute args
      options.parse! args
    end
  end
end
