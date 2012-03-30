module GHI
  class Milestone
    def self.options
      OptionParser.new do |opts|
        opts.banner = 'usage: ghi milestone [--list]'
        opts.separator ''
      end
    end

    def self.execute args
      options.parse! args.empty? ? ['-h'] : args
    end
  end
end
