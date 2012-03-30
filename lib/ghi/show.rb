module GHI
  class Show < Command
    def self.options
      OptionParser.new do |opts|
        opts.banner = 'usage: ghi show <issueno> [[<user>/]<repo>]'
        opts.separator ''
      end
    end

    def self.execute args
      options.parse! args.empty? ? ['-h'] : args
    end
  end
end
