module GHI
  module Commands
    class Label < Command
      attr_accessor :name

      #--
      # FIXME: This does too much. Opt for a secondary command, e.g.,
      #
      #   ghi label add <labelname>
      #   ghi label rm <labelname>
      #   ghi label <issueno> <labelname>...
      #++
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi label <labelname> [-c <color>] [-r <newname>]
   or: ghi label -D <labelname>
   or: ghi label <issueno> [-a] [-d] [-f]
   or: ghi label -l [<issueno>]
EOF
          opts.separator ''
          opts.on '-l', '--list [<issueno>]', 'list label names' do |n|
            self.action = 'index'
            @issue ||= n
          end
          opts.on '-D', '--delete', 'delete label' do
            self.action = 'destroy'
          end
          opts.separator ''
          opts.separator 'Label modification options'
          opts.on(
            '-c', '--color <color>', 'color name or 6-character hex code'
          ) do |color|
            assigns[:color] = to_hex color
            self.action ||= 'create'
          end
          opts.on '-r', '--rename <labelname>', 'new label name' do |name|
            assigns[:name] = name
            self.action = 'update'
          end
          opts.separator ''
          opts.separator 'Issue modification options'
          opts.on '-a', '--add', 'add labels to issue' do
            self.action = issue ? 'add' : 'create'
          end
          opts.on '-d', '--delete', 'remove labels from issue' do
            self.action = issue ? 'remove' : 'destroy'
          end
          opts.on '-f', '--force', 'replace existing labels' do
            self.action = issue ? 'replace' : 'update'
          end
          opts.separator ''
        end
      end

      def execute
        extract_issue
        require_repo
        options.parse! args.empty? ? %w(-l) : args

        if issue
          self.action ||= 'add'
          self.name = args.shift.to_s.split ','
          self.name.concat args
        else
          self.action ||= 'create'
          self.name ||= args.shift
        end

        send action
      end

      protected

      def index
        if issue
          uri = "/repos/#{repo}/issues/#{issue}/labels"
        else
          uri = "/repos/#{repo}/labels"  
        end
        labels = throb { api.get uri }.body
        if labels.empty?
          puts 'None.'
        else
          puts labels.map { |label|
            name = label['name']
            colorize? ? bg(label['color']) { " #{name} " } : name
          }
        end
      end

      def create
        label = throb {
          api.post "/repos/#{repo}/labels", assigns.merge(:name => name)
        }.body
        return update if label.nil?
        puts "%s created." % bg(label['color']) { " #{label['name']} "}
      rescue Client::Error => e
        if e.errors.find { |error| error['code'] == 'already_exists' }
          return update
        end
        raise
      end

      def update
        label = throb {
          api.patch "/repos/#{repo}/labels/#{name}", assigns
        }.body
        puts "%s updated." % bg(label['color']) { " #{label['name']} "}
      end

      def destroy
        throb { api.delete "/repos/#{repo}/labels/#{name}" }
        puts "[#{name}] deleted."
      end

      def add
        labels = throb {
          api.post "/repos/#{repo}/issues/#{issue}/labels", name
        }.body
        puts "Issue #%d labeled %s." % [issue, format_labels(labels)]
      end

      def remove
        case name.length
        when 0
          throb { api.delete base_uri }
          puts "Labels removed."
        when 1
          labels = throb { api.delete "#{base_uri}/#{name.join}" }.body
          if labels.empty?
            puts "Issue #%d unlabeled." % issue
          else
            puts "Issue #%d labeled %s." % [issue, format_labels(labels)]
          end
        else
          labels = throb {
            api.get "/repos/#{repo}/issues/#{issue}/labels"
          }.body
          self.name = labels.map { |l| l['name'] } - name
          replace
        end
      end

      def replace
        labels = throb { api.put base_uri, name }.body
        if labels.empty?
          puts "Issue #%d unlabeled." % issue
        else
          puts "Issue #%d labeled %s." % [issue, format_labels(labels)]
        end
      end

      private

      def base_uri
        "/repos/#{repo}/#{issue ? "issues/#{issue}/labels" : 'labels'}"
      end
    end
  end
end
