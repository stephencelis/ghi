# encoding: utf-8
require 'date'
require 'erb'

module GHI
  module Formatting
    autoload :Colors, 'ghi/formatting/colors'
    include Colors

    CURSOR = {
      :up     => lambda { |n| "\e[#{n}A" },
      :column => lambda { |n| "\e[#{n}G" },
      :hide   => "\e[?25l",
      :show   => "\e[?25h"
    }

    THROBBERS = [
      %w(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏),
      %w(⠋ ⠙ ⠚ ⠞ ⠖ ⠦ ⠴ ⠲ ⠳ ⠓),
      %w(⠄ ⠆ ⠇ ⠋ ⠙ ⠸ ⠰ ⠠ ⠰ ⠸ ⠙ ⠋ ⠇ ⠆ ),
      %w(⠋ ⠙ ⠚ ⠒ ⠂ ⠂ ⠒ ⠲ ⠴ ⠦ ⠖ ⠒ ⠐ ⠐ ⠒ ⠓ ⠋),
      %w(⠁ ⠉ ⠙ ⠚ ⠒ ⠂ ⠂ ⠒ ⠲ ⠴ ⠤ ⠄ ⠄ ⠤ ⠴ ⠲ ⠒ ⠂ ⠂ ⠒ ⠚ ⠙ ⠉ ⠁),
      %w(⠈ ⠉ ⠋ ⠓ ⠒ ⠐ ⠐ ⠒ ⠖ ⠦ ⠤ ⠠ ⠠ ⠤ ⠦ ⠖ ⠒ ⠐ ⠐ ⠒ ⠓ ⠋ ⠉ ⠈),
      %w(⠁ ⠁ ⠉ ⠙ ⠚ ⠒ ⠂ ⠂ ⠒ ⠲ ⠴ ⠤ ⠄ ⠄ ⠤ ⠠ ⠠ ⠤ ⠦ ⠖ ⠒ ⠐ ⠐ ⠒ ⠓ ⠋ ⠉ ⠈ ⠈ ⠉)
    ]

    def puts *strings
      strings = strings.flatten.map { |s|
        s.gsub(/@([^@\s]+)/) {
          if $1 == Authorization.username
            bright { fg(:yellow) { "@#$1" } }
          else
            bright { "@#$1" }
          end
        }
      }
      super strings
    end

    def page header = nil, throttle = 1
      $stdout = IO.popen('less -EKrX -b1', 'w') if $stdout == STDOUT
      puts header if header
      loop do
        yield
        sleep throttle
      end
    rescue Errno::EPIPE
      exit
    ensure
      unless $stdout == STDOUT
        $stdout.close_write
        $stdout = STDOUT
        print CURSOR[:show]
        exit
      end
    end

    def truncate string, reserved
      result = string.scan(/.{0,#{columns - reserved}}(?:\s|\Z)/).first.strip
      result << "..." if result != string
      result
    end

    def indent string, level = 4
      string = string.gsub(/\r/, '')
      string.gsub!(/[\t ]+$/, '')
      string.gsub!(/\n{3,}/, "\n\n")
      width = columns - level - 1
      lines = string.scan(
        /.{0,#{width}}(?:\s|\Z)|[\S]{#{width},}/ # TODO: Test long lines.
      ).map { |line| " " * level + line.chomp }
      format_markdown lines.join("\n").rstrip, level
    end

    def columns
      dimensions[1] || 80
    end

    def dimensions
      `stty size`.chomp.split(' ').map { |n| n.to_i }
    end

    #--
    # Specific formatters:
    #++

    def format_issues_header
      state = assigns[:state] || 'open'
      header = "# #{repo || 'Global,'} #{state} issues"
      if repo
        if milestone = assigns[:milestone]
          header.sub! repo, "#{repo} milestone ##{milestone}"
        end
        if assignee = assigns[:assignee]
          header << case assignee
            when '*'    then ', assigned'
            when 'none' then ', unassigned'
          else
            assignee = 'you' if Authorization.username == assignee
            ", assigned to #{assignee}"
          end
        end
        if mentioned = assigns[:mentioned]
          mentioned = 'you' if Authorization.username == mentioned
          header << ", mentioning #{mentioned}"
        end
      else
        header << case assigns[:filter]
          when 'created'    then ' you created'
          when 'mentioned'  then ' that mention you'
          when 'subscribed' then " you're subscribed to"
        else
          ' assigned to you'
        end
      end
      if labels = assigns[:labels]
        header << ", labeled #{assigns[:labels].gsub ',', ', '}"
      end
      if sort = assigns[:sort]
        header << ", by #{sort} #{reverse ? 'ascending' : 'descending'}"
      end
      format_state assigns[:state], header
    end

    # TODO: Show milestones.
    def format_issues issues, include_repo
      return 'None.' if issues.empty?

      include_repo and issues.each do |i|
        %r{/repos/[^/]+/([^/]+)} === i['url'] and i['repo'] = $1
      end

      nmax, rmax = %w(number repo).map { |f|
        issues.sort_by { |i| i[f].to_s.size }.last[f].to_s.size
      }

      issues.map { |i|
        n, title, labels = i['number'], i['title'], i['labels']
        l = 8 + nmax + rmax + no_color { format_labels labels }.to_s.length
        a = i['assignee'] && i['assignee']['login'] == Authorization.username
        l += 2 if a
        p = i['pull_request']['html_url'] and l += 2
        c = i['comments'] if i['comments'] > 0 and l += 2
        [
          " ",
          (i['repo'].to_s.rjust(rmax) if i['repo']),
          "#{bright { n.to_s.rjust nmax }}:",
          truncate(title, l),
          format_labels(labels),
          (fg('aaaaaa') { c } if c),
          (fg('aaaaaa') { '↑' } if p),
          (fg(:yellow) { '@' } if a)
        ].compact.join ' '
      }
    end

    # TODO: Show milestone, number of comments, pull request attached.
    def format_issue i
      ERB.new(<<EOF).result binding
<% p = i['pull_request']['html_url'] %>\
<%= bright { no_color { \
indent '%s%s: %s' % [p ? '↑' : '#', *i.values_at('number', 'title')], 0 } } %>
@<%= i['user']['login'] %> opened this <%= p ? 'pull request' : 'issue' %> \
<%= format_date DateTime.parse(i['created_at']) %>. \
<%= format_state i['state'], format_tag(i['state']), :bg %>\
<% if i['assignee'] || !i['labels'].empty? %>
<% if i['assignee'] %>@<%= i['assignee']['login'] %> is assigned. <% end %>\
<% unless i['labels'].empty? %><%= format_labels(i['labels']) %><% end %>\
<% end %>
<% if i['body'] && !i['body'].empty? %>\n<%= indent i['body'] %>
<% end %>

EOF
    end

    def format_comments comments
      return 'None.' if comments.empty?
      comments.map { |comment| format_comment comment }
    end

    def format_comment c
      <<EOF
@#{c['user']['login']} commented \
#{format_date DateTime.parse(c['created_at'])}:
#{indent c['body']}


EOF
    end

    def format_milestones milestones
      return 'None.' if milestones.empty?

      max = milestones.sort_by { |m|
        m['number'].to_s.size
      }.last['number'].to_s.size

      milestones.map { |m|
        due_on = m['due_on'] && DateTime.parse(m['due_on'])
        [
          "  #{bright { m['number'].to_s.rjust max }}:",
          fg((:red if due_on && due_on <= DateTime.now)) {
            truncate(m['title'], max + 4)
          }
        ].compact.join ' '
      }
    end

    def format_milestone m
      ERB.new(<<EOF).result binding
<%= bright { no_color { \
indent '#%s: %s' % m.values_at('number', 'title'), 0 } } %>
@<%= m['creator']['login'] %> created this milestone <%= m['created_at'] %>. \
<%= format_state m['state'], format_tag(m['state']), :bg %>
<% if m['due_on'] %>\
<% due_on = DateTime.parse m['due_on'] %>\
Due <%= fg((:red if due_on <= DateTime.now)) { format_date due_on } %>.
<% end %>\
<% if m['description'] && !m['description'].empty? %>
<%= indent m['description'] %>\
<% end %>
EOF
    end

    def format_state state, string = state, layer = :fg
      send(layer, state == 'closed' ? 'ff0000' : '2cc200') { string }
    end

    def format_labels labels
      return if labels.empty?
      [*labels].map { |l| bg(l['color']) { format_tag l['name'] } }.join ' '
    end

    def format_tag tag
      (colorize? ? ' %s ' : '[%s]') % tag
    end

    def format_markdown string, indent = 4
      # Headers.
      string.gsub!(/^( {#{indent}}\#{1,6} .+)$/, bright{'\1'})
      string.gsub!(
        /(^ {#{indent}}.+$\n^ {#{indent}}[-=]+$)/, bright{'\1'}
      )
      # Emphasis.
      string.gsub!(
        /(^|\s)(\*\w(?:[^*]*\w)?\*)(\s|$)/m, '\1' + underline{'\2'} + '\3'
      )
      string.gsub!(
        /(^|\s)(_\w(?:[^_]*\w)?_)(\s|$)/m, '\1' + underline{'\2'} + '\3'
      )
      # Strong.
      string.gsub!(
        /(^|\s)(\*{2}\w(?:[^*]*\w)?\*{2})(\s|$)/m, '\1' + bright{'\2'} + '\3'
      )
      string.gsub!(
        /(^|\s)(_{2}\w(?:[^_]*\w)?_{2})(\s|$)/m, '\1' + bright {'\2'} + '\3'
      )
      # Code.
      string.gsub!(
        /
          (^\ {#{indent}}```.*?$)(.+?^\ {#{indent}}```$)|
          (^|[^`])(`[^`]+`)([^`]|$)
        /mx,
        fg(c = '268bd2'){'\1'} + bg(c){'\2'} + '\3' + fg(c){'\4'} + '\5'
      )
      # URI.
      string.gsub!(
        %r{\b(<)?(https?://[\s]+|\w+@\w+)(>)?\b},
        '\1' + underline{'\2'} + '\3'
      )
      string
    end

    def format_date date
      days = (interval = DateTime.now - date).to_i.abs
      string = if days.zero?
        seconds, _ = interval.divmod Rational(1, 86400)
        hours, seconds = seconds.divmod 3600
        minutes, seconds = seconds.divmod 60
        if hours > 0
          "#{hours} hour#{'s' unless hours == 1}"
        elsif minutes > 0
          "#{minutes} minute#{'s' unless minutes == 1}"
        else
          "#{seconds} second#{'s' unless seconds == 1}"
        end
      else
        "#{days} day#{'s' unless days == 1}"
      end
      [string, interval < 0 ? 'from now' : 'ago'].join ' '
    end

    def throb position = 0, redraw = CURSOR[:up][1]
      return yield unless $stdout.tty?

      throb = THROBBERS[rand(THROBBERS.length)]
      throb.reverse! if rand > 0.5
      i = rand throb.length

      thread = Thread.new do
        dot = lambda do
          print("\r#{CURSOR[:column][position]}#{throb[i]}#{CURSOR[:hide]}")
          i = (i + 1) % throb.length
          sleep 0.1 and dot.call
        end
        dot.call
      end
      yield
    ensure
      if thread
        thread.kill
        puts "\r#{CURSOR[:column][position]}#{redraw}#{CURSOR[:show]}"
      end
    end
  end
end
