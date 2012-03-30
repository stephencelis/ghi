require 'optparse'

module GHI
  autoload :Command,   'ghi/command'

  autoload :List,      'ghi/list'
  autoload :Show,      'ghi/show'
  autoload :Open,      'ghi/open'
  autoload :Close,     'ghi/close'
  autoload :Edit,      'ghi/edit'
  autoload :Comment,   'ghi/comment'
  autoload :Label,     'ghi/label'
  autoload :Assign,    'ghi/assign'
  autoload :Milestone, 'ghi/milestone'

  autoload :Reopen,    'ghi/reopen'
  autoload :Unassign,  'ghi/unassign'

  autoload :Help,      'ghi/help'
  autoload :Version,   'ghi/version'

  def self.execute args
    STDOUT.sync = true

    if index = args.index { |arg| arg !~ /^-/ }
      command_name = args.delete_at index
      command_args = args.slice! index, args.length
    end
    command_args ||= []

    option_parser = OptionParser.new do |opts|
      opts.banner = 'usage: ghi [--version] [-h|--help] <command> [<args>]'
      opts.on('-h', '--help') {
        command_args.unshift command_name, *args
        args.clear
        command_name = 'help'
      }
      opts.on('--version') { command_name = 'version' }
      opts.on('-v')        { raise OptionParser::InvalidOption }
    end

    begin
      option_parser.parse! args
    rescue OptionParser::InvalidOption => e
      warn "#{e.message.capitalize}\n"
      abort option_parser.banner
    end

    if command_name.nil? || command_name == 'help'
      Help.execute command_args, option_parser.banner
    else
      begin
        command = const_get command_name.capitalize
        raise NameError unless command.respond_to? :execute
      rescue NameError
        abort "ghi: '#{command_name}' is not a ghi command. See 'ghi --help'."
      end

      # Post-command help option parsing.
      Help.execute [command_name] if command_args.first == '--help'

      begin
        command.execute command_args
      rescue OptionParser::ParseError => e
        warn "#{e.message.capitalize}\n"
        abort command.options.to_s
      end
    end
  end
end
