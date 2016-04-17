require 'date'

module GHI
  module Commands
    class Milestone < Command
      attr_accessor :edit
      attr_accessor :reverse
      attr_accessor :web

      #--
      # FIXME: Opt for better interface, e.g.,
      #
      #   ghi milestone [-v | --verbose] [--[no-]closed]
      #   ghi milestone add <name> <description>
      #   ghi milestone rm <milestoneno>
      #++
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi milestone [<modification options>] [<milestoneno>]
   or: ghi milestone -D <milestoneno>
   or: ghi milestone -l [-c] [-v]
EOF
          opts.separator ''
          opts.on '-l', '--list', 'list milestones' do
            self.action = 'index'
          end
          opts.on '-c', '--[no-]closed', 'show closed milestones' do |closed|
            assigns[:state] = closed ? 'closed' : 'open'
          end
          opts.on(
            '-S', '--sort <on>', %w(due_date completeness),
            {'d'=>'due_date', 'due'=>'due_date', 'c'=>'completeness'},
            "'due_date' or 'completeness'"
          ) do |sort|
            assigns[:sort] = sort
          end
          opts.on '--reverse', 'reverse (ascending) sort order' do
            self.reverse = !reverse
          end
          opts.on '-v', '--verbose', 'list milestones verbosely' do
            self.verbose = true
          end
          opts.on('-w', '--web') { self.web = true }
          opts.separator ''
          opts.separator 'Milestone modification options'
          opts.on(
            '-m', '--message [<text>]', 'change milestone description'
          ) do |text|
            self.action = 'create'
            self.edit = true
            next unless text
            assigns[:title], assigns[:description] = text.split(/\n+/, 2)
          end
          # FIXME: We already describe --[no-]closed; describe this, too?
          opts.on(
            '-s', '--state <in>', %w(open closed),
            {'o'=>'open', 'c'=>'closed'}, "'open' or 'closed'"
          ) do |state|
            self.action = 'create'
            assigns[:state] = state
          end
          opts.on(
            '--due <on>', 'when milestone should be complete',
            "e.g., '2012-04-30'"
          ) do |date|
            self.action = 'create'
            begin
              # TODO: Better parsing.
              assigns[:due_on] = DateTime.parse(date).strftime
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
        require_repo
        extract_milestone

        begin
          options.parse! args
        rescue OptionParser::AmbiguousOption => e
          fallback.parse! e.args
        end

        milestone and case action
          when 'create' then self.action = 'update'
          when 'index'  then self.action = 'show'
        end

        if reverse
          assigns[:sort] ||= 'created'
          assigns[:direction] = 'asc'
        end

        case action
        when 'index'
          if web
            Web.new(repo).open 'milestones', assigns
          else
            assigns[:per_page] = 100
            state = assigns[:state] || 'open'
            print format_state state, "# #{repo} #{state} milestones"
            print "\n" unless paginate?
            res = throb(0, format_state(state, '#')) { api.get uri, assigns }
            page do
              milestones = res.body
              if verbose
                puts milestones.map { |m| format_milestone m }
              else
                puts format_milestones(milestones)
              end
              break unless res.next_page
              res = throb { api.get res.next_page }
            end
          end
        when 'show'
          if web
            List.execute %W(-w -M #{milestone} -- #{repo})
          else
            m = throb { api.get uri }.body
            page do
              puts format_milestone(m)
              puts 'Issues:'
              args.unshift(*%W(-q -M #{milestone} -- #{repo}))
              args.unshift '-v' if verbose
              List.execute args
              break
            end
          end
        when 'create'
          if web
            Web.new(repo).open 'issues/milestones/new'
          else
            if assigns[:title].nil?
              e = Editor.new 'GHI_MILESTONE.md'
              message = e.gets format_milestone_editor
              e.unlink 'Empty milestone.' if message.nil? || message.empty?
              assigns[:title], assigns[:description] = message.split(/\n+/, 2)
            end
            m = throb { api.post uri, assigns }.body
            puts 'Milestone #%d created.' % m['number']
            e.unlink if e
          end
        when 'update'
          if web
            Web.new(repo).open "issues/milestones/#{milestone}/edit"
          else
            if edit || assigns.empty?
              m = throb { api.get "/repos/#{repo}/milestones/#{milestone}" }.body
              e = Editor.new "GHI_MILESTONE_#{milestone}.md"
              message = e.gets format_milestone_editor(m)
              e.unlink 'Empty milestone.' if message.nil? || message.empty?
              assigns[:title], assigns[:description] = message.split(/\n+/, 2)
            end
            if assigns[:title] && m
              t_match = assigns[:title].strip == m['title'].strip
              if assigns[:description]
                b_match = assigns[:description].strip == m['description'].strip
              end
              if t_match && b_match
                e.unlink if e
                abort 'No change.' if assigns.dup.delete_if { |k, v|
                  [:title, :description].include? k
                }
              end
            end
            m = throb { api.patch uri, assigns }.body
            puts format_milestone(m)
            puts 'Updated.'
            e.unlink if e
          end
        when 'destroy'
          require_milestone
          throb { api.delete uri }
          puts 'Milestone deleted.'
        end
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
