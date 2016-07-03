module GHI
  module Commands
    class Lock < Command
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi lock [options] <issueno>
EOF
          opts.separator ''
          opts.separator 'Issue modification options'
          opts.on '-m', '--message [<text>]', 'lock with message' do |text|
            assigns[:comment] = text
          end
          opts.separator ''
        end
      end

      def execute
        options.parse! args
        require_repo
        require_issue

        if assigns.key? :comment
          Comment.execute [
            issue, '-m', assigns[:comment], '--', repo
          ].compact
        end

        throb { api.put "/repos/#{repo}/issues/#{issue}/lock" }

        puts 'Locked.'
      rescue Client::Error => e
        raise unless error = e.errors.first
        abort "%s %s %s %s." % [
          error['resource'],
          error['field'],
          [*error['value']].join(', '),
          error['code']
        ]
      end
    end
  end
end
