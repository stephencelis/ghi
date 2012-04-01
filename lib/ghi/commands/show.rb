module GHI
  module Commands
    class Show < Command
      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi show <issueno> [[<user>/]<repo>]'
          opts.separator ''
        end
      end

      def execute
        require_issue
        require_repo

        i = api.get("/repos/#{repo}/issues/#{issue}")

        assignee = i['assignee'] && "@#{i['assignee']['login']}"
        template = {
          :number   => i['number'],
          :opened   => i['created_at'],
          :user     => "@#{i['user']['login']}",
          :title    => i['title'],
          :assignee => assignee || fg(:white) { '(none)' },
          :state    => format_state(i['state']),
          :labels   => format_labels(i['labels'])
        }
        puts <<EOF % template
    number: %{number}
    opened: %{opened} by %{user}
     title: %{title}
  assignee: %{assignee}
     state: %{state}
    labels: %{labels}

EOF
      end
    end
  end
end
