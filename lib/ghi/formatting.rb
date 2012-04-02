# encoding: utf-8
require 'date'
require 'erb'

module GHI
  module Formatting
    THROBBERS = [
      %w(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏),
      %w(⠋ ⠙ ⠚ ⠞ ⠖ ⠦ ⠴ ⠲ ⠳ ⠓),
      %w(⠄ ⠆ ⠇ ⠋ ⠙ ⠸ ⠰ ⠠ ⠰ ⠸ ⠙ ⠋ ⠇ ⠆ ),
      %w(⠋ ⠙ ⠚ ⠒ ⠂ ⠂ ⠒ ⠲ ⠴ ⠦ ⠖ ⠒ ⠐ ⠐ ⠒ ⠓ ⠋),
      %w(⠁ ⠉ ⠙ ⠚ ⠒ ⠂ ⠂ ⠒ ⠲ ⠴ ⠤ ⠄ ⠄ ⠤ ⠴ ⠲ ⠒ ⠂ ⠂ ⠒ ⠚ ⠙ ⠉ ⠁),
      %w(⠈ ⠉ ⠋ ⠓ ⠒ ⠐ ⠐ ⠒ ⠖ ⠦ ⠤ ⠠ ⠠ ⠤ ⠦ ⠖ ⠒ ⠐ ⠐ ⠒ ⠓ ⠋ ⠉ ⠈),
      %w(⠁ ⠁ ⠉ ⠙ ⠚ ⠒ ⠂ ⠂ ⠒ ⠲ ⠴ ⠤ ⠄ ⠄ ⠤ ⠠ ⠠ ⠤ ⠦ ⠖ ⠒ ⠐ ⠐ ⠒ ⠓ ⠋ ⠉ ⠈ ⠈ ⠉)
    ]

    autoload :Colors, 'ghi/formatting/colors'
    include Colors

    def puts *strings
      strings = strings.flatten.map { |s|
        highlight s.to_s, /@#{Authorization.username}\b/
      }
      Kernel.puts strings
    end

    def truncate string, reserved
      result = string.scan(/.{0,#{columns - reserved}}(?:\s|\Z)/).first.strip
      result << "..." if result != string
      result
    end

    def indent string, level = 4
      string = string.gsub(/\n{3,}/, "\n\n")
      lines = string.scan(/.{0,#{columns - level - 1}}(?:\s|\Z)/).map { |line|
        " " * level + line
      }
      lines.pop if lines.last.empty?
      string = lines.join("\n")
      string.gsub(/\r/, '').gsub(/[\t ]+$/, '').gsub(/\n{2,}/, "\n\n")
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
      header = "# #{repo || 'Global,'} #{assigns[:state] || 'open'} issues"
      if repo
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
        [
          " ",
          (i['repo'].to_s.rjust(rmax) if i['repo']),
          "#{bright { n.to_s.rjust nmax }}:",
          truncate(title, l),
          format_labels(labels),
          (bright { fg(:yellow) { '@' } } if a)
        ].compact.join ' '
      }
    end

    def format_issue i
      ERB.new(<<EOF).result(binding).sub(/\n{2,}\Z/m, "\n\n")
<%= bright { indent '#%s: %s' % i.values_at('number', 'title'), 0 } %>
@<%= i['user']['login'] %> opened this issue <%= i['created_at'] %>. \
<%= format_state i['state'], format_tag(i['state']), :bg %>
<% if i['assignee'] %>\
@<%= i['assignee']['login'] %> is assigned. \
<% end %>\
<% unless i['labels'].empty? %>\
<%= format_labels(i['labels']) %>
<% end %>
<% if i['body'] && !i['body'].empty? %>\
<%= indent i['body'] %>\
<% end %>
EOF
    end

    def format_comments comments
      return 'None.' if comments.empty?
      comments.map { |comment| format_comment comment }
    end

    def format_comment c
      <<EOF
@#{c['user']['login']} commented #{c['created_at']}:

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
      ERB.new(<<EOF).result(binding).sub(/\n{2,}\Z/m, "\n\n")
<%= bright { indent '#%s: %s' % m.values_at('number', 'title'), 0 } %>
@<%= m['creator']['login'] %> created this milestone <%= m['created_at'] %>. \
<%= format_state m['state'], format_tag(m['state']), :bg %>
<% if m['due_on'] %>\
<% due_on = DateTime.parse m['due_on'] %>\
Due on <%= fg((:red if due_on <= DateTime.now)) { due_on.to_date } %>.
<% end %>\
<% if m['description'] && !m['description'].empty? %>
<%= indent m['description'] %>\
<% end %>
EOF
    end

    def format_state state, string = state, layer = :fg
      send(layer, state == 'closed' ? :red : :green) { string }
    end

    def format_labels labels
      return if labels.empty?
      [*labels].map { |l| bg(l['color']) { format_tag l['name'] } }.join ' '
    end

    def format_tag tag
      (colorize? ? ' %s ' : '[%s]') % tag
    end

    def throb position = 0, redraw = "\e[1A"
      throb = THROBBERS[rand(THROBBERS.length)]
      throb.reverse! if rand > 0.5

      i = 0
      thread = Thread.new do
        dot = lambda do
          print(
            "\r\e[#{position}G#{throb[i = (i + 1) % throb.length]}\e[?25l"
          )
          sleep 0.1 and dot.call
        end
        dot.call
      end
      yield
    ensure
      thread.kill
      puts "\r\e[#{position}G#{redraw}\e[?25h"
    end
  end
end
