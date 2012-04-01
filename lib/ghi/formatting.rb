module GHI
  module Formatting
    autoload :Colors, 'ghi/formatting/colors'
    include Colors

    def puts *strings
      strings = strings.flatten.map { |s|
        highlight s, /@?#{Authorization.username}\b/
      }
      Kernel.puts strings
    end

    def truncate string, reserved
      length = Integer(`stty size`[/\d+$/] || 80) - reserved
      result = string.scan(/.{0,#{length}}(?:\s|\Z)/).first.strip
      result << "..." if result != string
      result
    end

    def format_state state, string = state
      fg(state == 'closed' ? :red : :green) { string }
    end

    def format_labels labels
      return if labels.empty?
      format = colorize? ? ' %s ' : '[%s]'
      [*labels].map { |l| bg(l['color']) { format % l['name'] } }.join ' '
    end
  end
end
