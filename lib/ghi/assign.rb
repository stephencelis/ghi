module GHI
  class Assign
    def self.options
      OptionParser.new do |opts|
        opts.banner = 'usage: ghi assign <issueno>'
        opts.separator ''
      end
    end

    def self.execute args
      options.parse! args.empty? ? ['-h'] : args
    end
  end
end
