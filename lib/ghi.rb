require 'optparse'

module GHI
  autoload :Authorization, 'ghi/authorization'
  autoload :Client,        'ghi/client'
  autoload :Commands,      'ghi/commands'
  autoload :Formatting,    'ghi/formatting'

  class << self
    def execute args
      STDOUT.sync = true

      if index = args.index { |arg| arg !~ /^-/ }
        command_name = args.delete_at index
        command_args = args.slice! index, args.length
      end
      command_args ||= []

      option_parser = OptionParser.new do |opts|
        opts.banner = <<EOF
usage: ghi [--version] [-p|--paginate|--no-pager] [--help] <command> [<args>]
EOF
        opts.on('--version') { command_name = 'version' }
        opts.on '-p', '--paginate', '--[no-]pager' do |paginate|
          
        end
        opts.on '--help' do
          command_args.unshift command_name, *args
          args.clear
          command_name = 'help'
        end
        opts.on '--[no-]color' do |colorize|
          Formatting::Colors.colorize = colorize
        end
        opts.on('-v') { self.v = true }
        opts.on('-h') { raise OptionParser::InvalidOption }
      end

      begin
        option_parser.parse! args
      rescue OptionParser::InvalidOption => e
        warn e.message.capitalize
        abort option_parser.banner
      end

      if command_name.nil? || command_name == 'help'
        Commands::Help.execute command_args, option_parser.banner
      else
        begin
          command = Commands.const_get command_name.capitalize
        rescue NameError
          abort "ghi: '#{command_name}' is not a ghi command. See 'ghi --help'."
        end

        # Post-command help option parsing.
        Help.execute [command_name] if command_args.first == '--help'

        begin
          command.execute command_args
        rescue OptionParser::ParseError => e
          warn "#{e.message.capitalize}\n"
          abort command.new([]).options.to_s
        end
      end
    rescue Authorization::Required => e
      retry if Authorization.authorize!
      warn e.message
      if Authorization.token
        warn <<EOF

Not authorized for this action with your token. To regenerate a new token:
EOF
      end
      warn <<EOF

Please run 'ghi config --authorize'
EOF
      abort
    end

    attr_accessor :v
    alias v? v
  end
end
