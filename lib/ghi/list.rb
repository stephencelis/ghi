require 'date'

module GHI
  class List < Command
    #   usage: ghi list [options] [[<user>/]<repo>]
    #
    #       -g, --global                     all of your issues on GitHub
    #       -s, --state <in>                 open or closed
    #       -L, --label <labelname>...       by label(s)
    #           --sort <on>                  created, updated, or comments
    #           --reverse                    reverse (ascending) sort order
    #           --since <date>               issues more recent than
    #
    #   Global options
    #       -f, --filter <by>                assigned, created, mentioned, or
    #                                        subscribed
    #
    #   Project options
    #       -M, --milestone <n>
    #       -u, --[no-]assignee <user>
    #       -U, --mentioned <user>
    def self.options
      OptionParser.new do |opts|
        opts.banner = 'usage: ghi list [options] [[<user>/]<repo>]'
        opts.separator ''
        opts.on '-g', '--global', 'all of your issues on GitHub' do
          assigns[:global] = true
        end
        opts.on(
          '-s', '--state <in>', %w(open closed), {'o'=>'open','c'=>'closed'},
          'open or closed'
        ) do |state|
          assigns[:state] = state
        end
        opts.on(
          '-L', '--label <labelname>...', Array, 'by label(s)'
        ) do |labels|
          assigns[:labels] = labels
        end
        opts.on(
          '--sort <on>', %w(created updated comments),
          {'c'=>'created','u'=>'updated','m'=>'comments'},
          'created, updated, or comments'
        ) do |sort|
          assigns[:sort] = sort
        end
        opts.on '--reverse', 'reverse (ascending) sort order' do
          assigns[:reverse] = !assigns[:reverse]
        end
        opts.on '--since <date>', 'issues more recent than' do |date|
          begin
            assigns[:date] = Date.parse date # TODO: Better parsing.
          rescue ArgumentError => e
            raise OptionParser::InvalidArgument, e.message
          end
        end
        opts.separator ''
        opts.separator 'Global options'
        opts.on(
          '-f', '--filter <by>',
          %w(assigned created mentioned subscribed),
          {'a'=>'assigned','c'=>'created','m'=>'mentioned','s'=>'subscribed'},
          'assigned, created, mentioned, or subscribed'
        ) do |filter|
          assigns[:filter] = filter
        end
        opts.separator ''
        opts.separator 'Project options'
        opts.on '-M', '--milestone <n>', Integer do |milestone|
          assigns[:milestone] = milestone
        end
        opts.on '-u', '--[no-]assignee <user>' do |assignee|
          assigns[:assignee] = assignee
        end
        opts.on '-U', '--mentioned <user>' do |mentioned|
          assigns[:mentioned] = mentioned
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
