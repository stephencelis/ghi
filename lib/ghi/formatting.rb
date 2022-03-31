# encoding: utf-8
require 'date'
require 'erb'

module GHI
  module Formatting
    class << self
      attr_accessor :paginate
    end
    self.paginate = true # Default.

    attr_accessor :paging

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
        s.gsub(/(^| *)@([\w-]+)/) {
          if $2 == Authorization.username
            bright { fg(:yellow) { "#$1@#$2" } }
          else
            bright { "#$1@#$2" }
          end
        }
      }
      super strings
    end

    def page header = nil, throttle = 0
      if paginate?
        pager   = GHI.config('ghi.pager') || GHI.config('core.pager')
        pager ||= ENV['PAGER']
        pager ||= 'less'
        pager  += ' -EKRX -b1' if pager =~ /^less( -[EKRX]+)?$/

        if pager && !pager.empty? && pager != 'cat'
          $stdout = IO.popen pager, 'w'
        end

        puts header if header
        self.paging = true
      end

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

    def paginate?
      ($stdout.tty? && $stdout == STDOUT && Formatting.paginate) || paging?
    end

    def paging?
      !!paging
    end

    def truncate string, reserved
      return string unless paginate?
      space=columns - reserved
      space=5 if space < 5
      result = string.scan(/.{0,#{space}}(?:\s|\Z)/).first.strip
      result << "..." if result != string
      result
    end

    def indent string, level = 4, maxwidth = columns
      string = string.gsub(/\r/, '')
      string.gsub!(/[\t ]+$/, '')
      string.gsub!(/\n{3,}/, "\n\n")
      width = maxwidth - level - 1
      lines = string.scan(
        /.{0,#{width}}(?:\s|\Z)|[\S]{#{width},}/ # TODO: Test long lines.
      ).map { |line| " " * level + line.chomp }
      format_markdown lines.join("\n").rstrip, level
    end

    def columns
      dimensions[1] || 80
    end

    def dimensions
      `stty size 2>/dev/null`.chomp.split(' ').map { |n| n.to_i }
    end

    #--
    # Specific formatters:
    #++

    def format_username username
      username == Authorization.username ? 'you' : username
    end

    def format_issues_header
      state = assigns[:state] ||= 'open'
      org = assigns[:org] ||= nil
      header = "# #{repo || org || 'Global,'} #{state} issues"
      if repo
        if milestone = assigns[:milestone]
          case milestone
            when '*'    then header << ' with a milestone'
            when 'none' then header << ' without a milestone'
          else
            header.sub! repo, "#{repo} milestone ##{milestone}"
          end
        end
        if assignee = assigns[:assignee]
          header << case assignee
            when '*'    then ', assigned'
            when 'none' then ', unassigned'
          else
            ", assigned to #{format_username assignee}"
          end
        end
        if mentioned = assigns[:mentioned]
          header << ", mentioning #{format_username mentioned}"
        end
      else
        header << case assigns[:filter]
          when 'created'    then ' you created'
          when 'mentioned'  then ' that mention you'
          when 'subscribed' then " you're subscribed to"
          when 'all'        then ' that you can see'
        else
          ' assigned to you'
        end
      end
      if creator = assigns[:creator]
        header << " #{format_username creator} created"
      end
      if labels = assigns[:labels]
        header << ", labeled #{labels.gsub ',', ', '}"
      end
      if excluded_labels = assigns[:exclude_labels]
        header << ", excluding those labeled #{excluded_labels.gsub ',', ', '}"
      end
      if sort = assigns[:sort] || GHI.config('ghi.sort')
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
        l = 9 + nmax + rmax + no_color { format_labels labels }.to_s.length
        a = i['assignee']
        a_is_me = a && a['login'] == Authorization.username
        l += a['login'].to_s.length + 2 if a
        p = i['pull_request']['html_url'] and l += 2 if i.key?('pull_request')
        c = i['comments']
        l += c.to_s.length + 1 unless c == 0
        m = i['milestone']
        [
          " ",
          (i['repo'].to_s.rjust(rmax) if i['repo']),
          format_number(n.to_s.rjust(nmax)),
          truncate(title, l),
          (format_labels(labels) unless assigns[:dont_print_labels]),
          (fg(:green) { m['title'] } if m),
          (fg('aaaaaa') { c } unless c == 0),
          (fg('aaaaaa') { '↑' } if p),
          (fg(a_is_me ? :yellow : :gray) { "@#{a['login']}" } if a),
          (fg('aaaaaa') { '‡' } if m)
        ].compact.join ' '
      }
    end

    def extract_milestones_from_issues issues
      return 'None.' if issues.empty?

      nmax, rmax = %w(number repo).map { |f|
        issues.sort_by { |i| i[f].to_s.size }.last[f].to_s.size
      }

      milestones = {}
      extracted_milestones = []
      milestone_index = 0
      issues.map { |i|
        milestone = i['milestone']
        milestone["issues"] = [] if milestone && !(milestones.key? milestone["id"])
        if milestone
          if !milestones.key? milestone["id"]
            milestones.merge!({milestone["id"] => milestone_index })
            i.delete "milestone"
            milestone["issues"] << i
            extracted_milestones << milestone
            milestone_index += 1
          else
            pos_of_existent_milestone = milestones[milestone["id"]]
            i.delete "milestone"
            extracted_milestones[pos_of_existent_milestone]["issues"] << i
          end
        end
      }
      extracted_milestones.sort! { |m1, m2| m1['number'] <=> m2['number'] }
    end

    def format_issues_by_milestone issues, include_repo
      issues_by_milestone = extract_milestones_from_issues issues

      nmax, rmax = %w(number repo).map { |f|
        issues.sort_by { |i| i[f].to_s.size }.last[f].to_s.size
      }

      l = 9 + nmax + rmax

      issues_by_milestone.map { |milestone|
        title =  milestone['title'] if milestone["issues"]
        [
          ("\n  " if milestone["issues"]),
          ("Milestone: " + fg(:green) { truncate(title,l) } if title),
             (format_issues(milestone["issues"], include_repo))
        ].compact
      }
    end

    def format_number n
      colorize? ? "#{bright { n }}:" : "#{n} "
    end

    # TODO: Show milestone, number of comments, pull request attached.
    def format_issue i, width = columns
      return unless i['created_at']
      ERB.new(<<EOF).result binding
<% p = i['pull_request']['html_url'] if i.key?('pull_request') %>\
<%= bright { no_color { indent '%s%s: %s' % [p ? '↑' : '#', \
*i.values_at('number', 'title')], 0, width } } %>
@<%= i['user']['login'] %> opened this <%= p ? 'pull request' : 'issue' %> \
<%= format_date DateTime.parse(i['created_at']) %>. \
<% if i['merged'] %><%= format_state 'merged', format_tag('merged'), :bg %><% end %> \
<%= format_state i['state'], format_tag(i['state']), :bg %> \
<% unless i['comments'] == 0 %>\
<%= fg('aaaaaa'){
  template = "%d comment"
  template << "s" unless i['comments'] == 1
  '(' << template % i['comments'] << ')'
} %>\
<% end %>\
<% if i['assignee'] || !i['labels'].empty? %>
<% if i['assignee'] %>@<%= i['assignee']['login'] %> is assigned. <% end %>\
<% unless i['labels'].empty? %><%= format_labels(i['labels']) %><% end %>\
<% end %>\
<% if i['milestone'] %>
Milestone #<%= i['milestone']['number'] %>: <%= i['milestone']['title'] %>\
<%= " \#{bright{fg(:yellow){'⚠'}}}" if past_due? i['milestone'] %>\
<% end %>
<% if i['body'] && !i['body'].empty? %>
<%= indent i['body'], 4, width %>
<% end %>

EOF
    end

    def format_comments_and_events elements
      return 'None.' if elements.empty?
      elements.map do |element|
        if event = element['event']
          format_event(element) unless unimportant_event?(event)
        else
          format_comment(element)
        end
      end.compact
    end

    def format_comment c, width = columns
      <<EOF
@#{c['user']['login']} commented \
#{format_date DateTime.parse(c['created_at'])}:
#{indent c['body'], 4, width}


EOF
    end

    def format_event e, width = columns
      reference = e['commit_id']
      <<EOF
#{bright { '⁕' }} #{format_event_type(e['event'])} by @#{e['actor']['login']}\
#{" through #{underline { reference[0..6] }}" if reference} \
#{format_date DateTime.parse(e['created_at'])}

EOF
    end

    def format_milestones milestones
      return 'None.' if milestones.empty?

      max = milestones.sort_by { |m|
        m['number'].to_s.size
      }.last['number'].to_s.size

      milestones.map { |m|
        line = ["  #{m['number'].to_s.rjust max }:"]
        space = past_due?(m) ? 6 : 4
        line << truncate(m['title'], max + space)
        line << '⚠' if past_due? m
        percent m, line.join(' ')
      }
    end

    def format_milestone m, width = columns
      ERB.new(<<EOF).result binding
<%= bright { no_color { \
indent '#%s: %s' % m.values_at('number', 'title'), 0, width } } %>
@<%= m['creator']['login'] %> created this milestone \
<%= format_date DateTime.parse(m['created_at']) %>. \
<%= format_state m['state'], format_tag(m['state']), :bg %>
<% if m['due_on'] %>\
<% due_on = DateTime.parse m['due_on'] %>\
<% if past_due? m %>\
<%= bright{fg(:yellow){"⚠"}} %> \
<%= bright{fg(:red){"Past due by \#{format_date due_on, false}."}} %>
<% else %>\
Due in <%= format_date due_on, false %>.
<% end %>\
<% end %>\
<%= percent m %>
<% if m['description'] && !m['description'].empty? %>
<%= indent m['description'], 4, width %>
<% end %>

EOF
    end

    def past_due? milestone
      return false unless milestone['due_on']
      DateTime.parse(milestone['due_on']) <= DateTime.now
    end

    def percent milestone, string = nil
      open, closed = milestone.values_at('open_issues', 'closed_issues')
      complete = closed.to_f / (open + closed)
      complete = 0 if complete.nan?
      i = (columns * complete).round
      if string.nil?
        string = ' %d%% (%d closed, %d open)' % [complete * 100, closed, open]
      end
      string = string.ljust columns
      [bg('2cc200'){string[0, i]}, string[i, columns - i]].join
    end

    def format_state state, string = state, layer = :fg
      color_codes = {
        'closed' => 'ff0000',
        'open'   => '2cc200',
        'merged' => '511c7d',
      }
      send(layer, color_codes[state]) { string }
    end

    def format_labels labels
      return if labels.empty?
      [*labels].map { |l| bg(l['color']) { format_tag l['name'] } }.join ' '
    end

    def format_tag tag
      (colorize? ? ' %s ' : '[%s]') % tag
    end

    def format_event_type(event)
      color_codes = {
        'reopened' => '2cc200',
        'closed' => 'ff0000',
        'merged' => '9677b1',
        'assigned' => 'e1811d',
        'referenced' => 'aaaaaa'
      }
      fg(color_codes[event]) { event }
    end

    #--
    # Helpers:
    #++

    #--
    # TODO: DRY up editor formatters.
    #++
    def format_editor issue = nil
      message = ERB.new(<<EOF).result binding

Please explain the issue. The first line will become the title. Trailing
markdown comments (like these) will be ignored, and empty messages will
not be submitted. Issues are formatted with GitHub Flavored Markdown (GFM):

  http://github.github.com/github-flavored-markdown

On <%= repo %>

<%= no_color { format_issue issue, columns - 2 if issue } %>
EOF
      message.rstrip!
      message.gsub!(/(?!\A)^.*$/) { |line| line.rstrip }
      max_line_len = message.gsub(/(?!\A)^.*$/).max_by(&:length).length
      message.gsub!(/(?!\A)^.*$/) { |line| "<!-- #{line.ljust(max_line_len)} -->" }
      # Adding an extra newline for formatting
      message.insert 0, "\n"
      message.insert 0, [
        issue['title'] || issue[:title], issue['body'] || issue[:body]
      ].compact.join("\n\n") if issue
      message
    end

    def format_milestone_editor milestone = nil
      message = ERB.new(<<EOF).result binding

Describe the milestone. The first line will become the title. Trailing
markdown comments (like these) will be ignored, and empty messages will not be
submitted. Milestones are formatted with GitHub Flavored Markdown (GFM):

  http://github.github.com/github-flavored-markdown

On <%= repo %>

<%= no_color { format_milestone milestone, columns - 2 } if milestone %>
EOF
      message.rstrip!
      message.gsub!(/(?!\A)^.*$/) { |line| line.rstrip }
      max_line_len = message.gsub(/(?!\A)^.*$/).max_by(&:length).length
      message.gsub!(/(?!\A)^.*$/) { |line| "<!-- #{line.ljust(max_line_len)} -->" }
      message.insert 0, [
        milestone['title'], milestone['description']
      ].join("\n\n") if milestone
      message
    end

    def format_comment_editor issue, comment = nil
      message = ERB.new(<<EOF).result binding

Leave a comment. Trailing markdown comments (like these) will be ignored,
and empty messages will not be submitted. Comments are formatted with GitHub
Flavored Markdown (GFM):

  http://github.github.com/github-flavored-markdown

On <%= repo %> issue #<%= issue['number'] %>

<%= no_color { format_issue issue } if verbose %>\
<%= no_color { format_comment comment, columns - 2 } if comment %>
EOF
      message.rstrip!
      message.gsub!(/(?!\A)^.*$/) { |line| line.rstrip }
      max_line_len = message.gsub(/(?!\A)^.*$/).max_by(&:length).length
      message.gsub!(/(?!\A)^.*$/) { |line| "<!-- #{line.ljust(max_line_len)} -->" }
      message.insert 0, comment['body'] if comment
      message
    end

    def format_markdown string, indent = 4
      c = '268bd2'

      # Headers.
      string.gsub!(/^( {#{indent}}\#{1,6} .+)$/, bright{'\1'})
      string.gsub!(
        /(^ {#{indent}}.+$\n^ {#{indent}}[-=]+$)/, bright{'\1'}
      )
      # Strong.
      string.gsub!(
        /(^|\s)(\*{2}\w(?:[^*]*\w)?\*{2})(\s|$)/m, '\1' + bright{'\2'} + '\3'
      )
      string.gsub!(
        /(^|\s)(_{2}\w(?:[^_]*\w)?_{2})(\s|$)/m, '\1' + bright {'\2'} + '\3'
      )
      # Emphasis.
      string.gsub!(
        /(^|\s)(\*\w(?:[^*]*\w)?\*)(\s|$)/m, '\1' + underline{'\2'} + '\3'
      )
      string.gsub!(
        /(^|\s)(_\w(?:[^_]*\w)?_)(\s|$)/m, '\1' + underline{'\2'} + '\3'
      )
      # Bullets/Blockquotes.
      string.gsub!(/(^ {#{indent}}(?:[*>-]|\d+\.) )/, fg(c){'\1'})
      # URIs.
      string.gsub!(
        %r{\b(<)?(https?://\S+|[^@\s]+@[^@\s]+)(>)?\b},
        fg(c){'\1' + underline{'\2'} + '\3'}
      )

      # Inline code
      string.gsub!(/`([^`].+?)`(?=[^`])/, inverse { ' \1 ' })

      # Code blocks
      string.gsub!(/(?<indent>^\ {#{indent}})(```)\s*(?<lang>\w*$)(\n)(?<code>.+?)(\n)(^\ {#{indent}}```$)/m) do |m|
        highlight(Regexp.last_match)
      end

      string
    end

    def format_date date, suffix = true
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
      ago = interval < 0 ? 'from now' : 'ago' if suffix
      [string, ago].compact.join ' '
    end

    def throb position = 0, redraw = CURSOR[:up][1]
      return yield unless paginate?

      throb = THROBBERS[rand(THROBBERS.length)]
      throb.reverse! if rand > 0.5
      i = rand throb.length

      thread = Thread.new do
        dot = lambda do
          print "\r#{CURSOR[:column][position]}#{throb[i]}#{CURSOR[:hide]}"
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

    private

    def unimportant_event?(event)
      %w{ subscribed unsubscribed mentioned }.include?(event)
    end
  end
end
