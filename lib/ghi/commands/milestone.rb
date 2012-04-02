require 'date'

module GHI
  module Commands
    class Milestone < Command
      attr_accessor :reverse

      #   usage: ghi milestone [modification options] [<milestoneno>]
      #          [[<user>]/<repo>]
      #      or: ghi milestone -D <milestoneno> [[<user>/]<repo>]
      #      or: ghi milestone -l [-c]
      #
      #       -l, --list                       list milestones
      #       -c, --[no-]closed                show closed milestones
      #           --sort <on>                  due_date completeness
      #                                        due_date or completeness
      #           --reverse                    reverse (ascending) sort order
      #
      #   Milestone modification options
      #       -m, --message <text>             change milestone description
      #       -s, --state <in>                 open or closed
      #           --due <on>                   when milestone should be complete
      #       -D, --delete <milestoneno>       delete milestone
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi milestone [<modification options>] [<milestoneno>] [[<user>]/<repo>]
   or: ghi milestone -D <milestoneno> [[<user>/]<repo>]
   or: ghi milestone -l [-c] [[<user>/]<repo>]
EOF
          opts.separator ''
          opts.on '-l', '--list', 'list milestones' do
            extract_repo
            self.action = 'index'
          end
          opts.on '-c', '--[no-]closed', 'show closed milestones' do |closed|
            assigns[:state] = closed ? 'closed' : 'open'
          end
          opts.on(
            '--sort <on>', %(due_date completeness),
            {'d'=>'due_date', 'due'=>'due_date', 'c'=>'completeness'},
            'due_date or completeness'
          ) do |sort|
            assigns[:sort] = sort
          end
          opts.on '--reverse', 'reverse (ascending) sort order' do
            self.reverse = !reverse
          end
          opts.separator ''
          opts.separator 'Milestone modification options'
          opts.on(
            '-m', '--message <text>', 'change milestone description'
          ) do |text|
            self.action = 'create'
            assigns[:title], assigns[:description] = text.split(/\n+/, 2)
          end
          opts.on(
            '-s', '--state <in>', %w(open closed),
            {'o'=>'open', 'c'=>'closed'}, 'open or closed'
          ) do |state|
            self.action = 'create'
            assigns[:state] = state
          end
          opts.on '--due <on>', 'when milestone should be complete' do |date|
            self.action = 'create'
            begin
              # TODO: Better parsing.
              assigns[:due_on] = DateTime.parse(date).iso8601
            rescue ArgumentError => e
              raise OptionParser::InvalidArgument, e.message
            end
          end
          opts.on '-D', '--delete', 'delete milestone' do
            self.action = 'destroy'
          end
          opts.separator ''
        end
      end

      def execute
        self.action = 'index'
        extract_milestone
        begin
          options.parse! args
        rescue OptionParser::AmbiguousOption => e
          fallback.parse! e.args
        end

        milestone and self.action = case action
          when 'create' then 'update'
          when 'index'  then 'show'
        end

        if reverse
          assigns[:sort] ||= 'created'
          assigns[:direction] = 'asc'
        end

        case action
        when 'index'
          milestones = throb { api.get uri }
          puts format_milestones(milestones)
        when 'show'
          m = throb { api.get uri }
          puts format_milestone(m)
        when 'create'
          m = throb { api.post uri, assigns }
          puts 'Milestone #%d created.' % m['number']
        when 'update'
          throb { api.patch uri, assigns }
          puts 'Milestone updated.'
        when 'destroy'
          throb { api.delete uri }
          puts 'Milestone deleted.'
        end
      rescue Client::Error => e
        abort e.message
      end

      private

      def uri
        if milestone
          "/repos/#{repo}/milestones/#{milestone}"
        else
          "/repos/#{repo}/milestones"
        end
      end

      def fallback
        OptionParser.new do |opts|
          opts.on '-d' do
            self.action = 'destroy'
          end
        end
      end
    end
  end
end
