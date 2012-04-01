module GHI
  module Commands
    class Label < Command
      attr_accessor :action
      attr_accessor :name

      #   usage: ghi label <labelname> [-c <color>] [-r <newname>]
      #          [[<user>/]<repo>]
      #      or: ghi label -D <labelname> [[<user>/]<repo>]
      #      or: ghi label <issueno> [-a] [-d] [-f] <labelname>,...
      #          [[<user>/]<repo>]
      #      or: ghi label -l [<issueno>] [[<user>/]<repo>]
      #
      #       -l, --list                       list label names
      #       -D                               delete label
      #
      #   Label modification options
      #       -c, --color <color>              6 character hex code
      #       -r, --rename <labelname>         new label name
      #
      #   Issue modification options
      #       -a, --add                        add labels to issue
      #       -d, --delete                     remove labels from issue
      #       -f, --force                      replace existing labels
      def options
        OptionParser.new do |opts|
          opts.banner = <<EOF
usage: ghi label <labelname> [-c <color>] [-r <newname>] [[<user>/]<repo>]
   or: ghi label -D <labelname> [[<user>/]<repo>]
   or: ghi label <issueno> [-a] [-d] [-f] <labelname>,... [[<user>/]<repo>]
   or: ghi label -l [<issueno>] [[<user>/]<repo>]
EOF
          opts.separator ''
          opts.on '-l', '--list', 'list label names'  do
            self.action = 'index'
          end
          opts.on '-D', '--delete', 'delete label' do
            self.action = 'destroy'
          end
          opts.separator ''
          opts.separator 'Label modification options'
          opts.on '-c', '--color <color>', '6 character hex code' do |color|
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
        options.parse! args.empty? ? %w(-l) : args
        repo

        if issue
          self.action ||= 'add'
          self.name = args.shift.to_s.split ','
        else
          self.action ||= 'create'
          self.name ||= args.shift
        end

        send action
      rescue Client::Error => e
        abort e.message
      end

      protected

      def index
        puts api.get("/repos/#{repo}/labels").map { |label|
          bg(label['color']) { " #{label['name']} " }
        }
      end

      def create
        label = api.post(
          "/repos/#{repo}/labels", assigns.merge(name: name)
        )
        return update if label.nil?
        puts "%s created" % bg(label['color']) { " #{label['name']} "}
      rescue Client::Error => e
        if e.errors.find { |error| error['code'] == 'already_exists' }
          return update
        end
        raise
      end

      def update
        label = api.patch "/repos/#{repo}/labels/#{name}", assigns
        puts "%s updated" % bg(label['color']) { " #{label['name']} "}
      end

      def destroy
        api.delete "/repos/#{repo}/labels/#{name}"
        puts " #{name}  deleted"
      end

      def add
        labels = api.post "/repos/#{repo}/issues/#{issue}/labels", name
        labels.delete_if { |l| !name.include?(l['name']) }
        puts "Issue #%d labeled %s" % [issue, format_labels(labels)]
      end

      def remove
        case name.length
        when 0
          api.delete base_uri
          puts "Labels removed"
        when 1
          labels = api.delete "#{base_uri}/#{name.join}"
          puts "Issue #%d labeled %s" % [issue, format_labels(labels)]
        else
          labels = api.get "/repos/#{repo}/issues/#{issue}/labels"
          self.name = labels.map { |l| l['name'] } - name
          replace
        end
      end

      def replace
        api.put base_uri, name
      end

      private

      def base_uri
        "/repos/#{repo}/#{issue ? "issues/#{issue}/labels" : 'labels'}"
      end
    end
  end
end
