module GHI
  module Commands
    class Unlock < Command
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi unlock [options] <issueno>
EOF
          opts.separator ''
          opts.separator 'Issue modification options'
          opts.on '-m', '--message [<text>]', 'unlock with message' do |text|
            assigns[:comment] = text
          end
          opts.separator ''
        end
      end

      def execute
        options.parse! args
        require_repo
        require_issue

        throb { api.delete "/repos/#{repo}/issues/#{issue}/lock" }

        if assigns.key? :comment
          Comment.execute [
            issue, '-m', assigns[:comment], '--', repo
          ].compact
        end

        puts 'Unlocked.'
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
