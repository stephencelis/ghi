module GHI
  class List
    def self.options
      OptionParser.new do |opts|
        opts.banner = 'usage: ghi list [<options>] [<[user/]repo>]'
        opts.separator ''
        opts.on '-g', '--global', 'all of your issues on GitHub' do

        end
        opts.on(
          '-s', '--state <in>', %w(open closed), {'o'=>'open','c'=>'closed'},
          'open or closed'
        ) do |state|
          puts "State: #{state}"
        end
        opts.on(
          '-l', '--label <labelname>...', Array, 'by label(s)'
        ) do |labels|
          puts "Labels: #{labels.inspect}"
        end
        opts.on(
          '--sort <on>', %w(created updated comments),
          {'c'=>'created','u'=>'updated','m'=>'comments'},
          'created, updated, or comments'
        ) do |sort|
          puts "Sort: #{sort}"
        end
        opts.on '--reverse', 'reverse (ascending) sort order' do
          puts "Reversing..."
        end
        opts.on '--since <date>', 'issues more recent than' do |date|
          puts "Date: #{date}"
        end
        opts.separator ''
        opts.separator 'Global options'
        opts.on(
          '-f', '--filter <by>',
          %w(assigned created mentioned subscribed),
          {'a'=>'assigned','c'=>'created','m'=>'mentioned','s'=>'subscribed'},
          'assigned, created, mentioned, or subscribed'
        ) do |filter|
          puts "Filter: #{filter}"
        end
        opts.separator ''
        opts.separator 'Project options'
        opts.on '-m', '--milestone <n>', Integer do |milestone|
          puts "Milestone: #{milestone}"
        end
        opts.on '-u', '--[no-]assignee <user>' do |assignee|
          puts "Assignee: #{assignee.inspect}"
        end
        opts.on '--mentioned <user>' do |mentioned|
          puts "Mentioned: #{mentioned}"
        end
        opts.separator ''
      end
    end

    def self.execute args
      options.parse! args
      p args
    end
  end
end
