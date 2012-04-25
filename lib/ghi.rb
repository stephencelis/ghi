require 'optparse'

module GHI
  autoload :Authorization, 'ghi/authorization'
  autoload :Client,        'ghi/client'
  autoload :Commands,      'ghi/commands'
  autoload :Editor,        'ghi/editor'
  autoload :Formatting,    'ghi/formatting'
  autoload :Web,           'ghi/web'

  class << self
    def execute args
      STDOUT.sync = true

      double_dash = args.index { |arg| arg == '--' }
      if index = args.index { |arg| arg !~ /^-/ }
        if double_dash.nil? || index < double_dash
          command_name = args.delete_at index
          command_args = args.slice! index, args.length
        end
      end
      command_args ||= []

      option_parser = OptionParser.new do |opts|
        opts.banner = <<EOF
usage: ghi [--version] [-p|--paginate|--no-pager] [--help] <command> [<args>]
           [ -- [<user>/]<repo>]
EOF
        opts.on('--version') { command_name = 'version' }
        opts.on '-p', '--paginate', '--[no-]pager' do |paginate|
          GHI::Formatting.paginate = paginate
        end
        opts.on '--help' do
          command_args.unshift(*args)
          command_args.unshift command_name if command_name
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
        command_name = fetch_alias command_name, command_args
        begin
          command = Commands.const_get command_name.capitalize
        rescue NameError
          abort "ghi: '#{command_name}' is not a ghi command. See 'ghi --help'."
        end

        # Post-command help option parsing.
        Commands::Help.execute [command_name] if command_args.first == '--help'

        begin
          command.execute command_args
        rescue OptionParser::ParseError, Commands::MissingArgument => e
          warn "#{e.message.capitalize}\n"
          abort command.new([]).options.to_s
        rescue Client::Error => e
          if e.response.is_a?(Net::HTTPNotFound) && Authorization.token.nil?
            raise Authorization::Required
          else
            abort e.message
          end
        rescue SocketError => e
          abort "Couldn't find internet."
        rescue Errno::ECONNREFUSED => e
          abort "Couldn't connect to GitHub."
        rescue Errno::ETIMEDOUT => e
          abort 'Timed out looking for GitHub.'
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

Please run 'ghi config --auth <username>:<password>'
EOF
      exit 1
    end

    def config key
      var = key.gsub('core', 'git').gsub('.', '_').upcase
      value = ENV[var] || `git config #{key}`.chomp
      value unless value.empty?
    end

    attr_accessor :v
    alias v? v

    private

    ALIASES = Hash.new { |_, key|
      ['show', key] if /^\d+$/ === key
    }.update(
      'c'        => %w(close),
      'claim'    => %w(assign),
      'e'        => %w(edit),
      'l'        => %w(list),
      'L'        => %w(label),
      'm'        => %w(comment),
      'M'        => %w(milestone),
      'o'        => %w(open),
      'reopen'   => %w(open),
      'rm'       => %w(close),
      's'        => %w(show),
      'st'       => %w(list),
      'tag'      => %w(label),
      'unassign' => %w(assign -d)
    )

    def fetch_alias command, args
      return command unless fetched = ALIASES[command]
      command = fetched.shift
      args.unshift(*fetched)
      command
    end
  end
end
