module GHI
  module Commands
    class Aliases < Command
      def execute
        puts 'Usage: ghi <alias> [<args>]'
        puts ''
        puts format_aliases
        puts ''
        puts "See 'ghi <alias> --help' for more information on a specific command"
      end

      private

      def format_aliases(indent = 4)
        indent = ' ' * indent
        ALIASES.map do |al, cmd|
          "#{indent}#{sprintf("%-15s", al)}#{cmd.join(' ')}"
        end.join("\n")
      end

      ALIASES = Hash.new { |_, key|
        [key] if /^\d+$/ === key
      }.update(
        'claim'    => %w(assign),
        'create'   => %w(open),
        'e'        => %w(edit),
        'l'        => %w(list),
        'L'        => %w(label),
        'm'        => %w(comment),
        'M'        => %w(milestone),
        'new'      => %w(open),
        'o'        => %w(open),
        'p'        => %w(pull),
        'pf'       => %w(pull fetch),
        'pm'       => %w(pull merge),
        'ps'       => %w(pull show),
        'reopen'   => %w(open),
        'rm'       => %w(close),
        's'        => %w(show),
        'st'       => %w(list),
        'tag'      => %w(label),
        'unassign' => %w(assign -d),
        'update'   => %w(edit)
      )

      def self.fetch command, args
        return command unless fetched = ALIASES[command]

        # If the <command> is an issue number, check the options to see if an
        # edit or show is desired.
        if fetched.first =~ /^\d+$/
          edit_options = Commands::Edit.new([]).options.top.list
          edit_options.reject! { |arg| !arg.is_a?(OptionParser::Switch) }
          edit_options.map! { |arg| [arg.short, arg.long] }
          edit_options.flatten!
          fetched.unshift((edit_options & args).empty? ? 'show' : 'edit')
        end

        command = fetched.shift
        args.unshift(*fetched)
        command
      end
    end
  end
end
