require "optparse"
require "tempfile"
require "ghi"
require "ghi/api"
require "ghi/issue"

class GHI::CLI
  attr_reader :user, :repo, :api, :action, :state, :number, :title,
    :search_term

  def initialize
    option_parser.parse!(ARGV)

    `git config --get remote.origin.url`.match %r{([^:/]+)/([^/]+).git$}
    @user ||= $1
    @repo ||= $2
    @api = GHI::API.new user, repo

    case action
      when :search then search search_term, state
      when :list   then list state
      when :show   then show number
      when :open   then open title
      when :edit   then edit number
      when :close  then close number
      when :reopen then reopen number
      else puts option_parser
    end
  rescue GHI::API::InvalidConnection
    warn "#{File.basename $0}: not a GitHub repo"
  rescue GHI::API::ResponseError => e
    warn "#{File.basename $0}: #{e.message} (#{user}/#{repo})"
  rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
    warn "#{File.basename $0}: #{e.message}"
  end

  private

  def option_parser
    @option_parser ||= OptionParser.new { |opts|
      opts.banner = "Usage: #{File.basename $0} [options]"

      opts.on("-l", "--list", "--search", "--show [state|term|number]") do |v|
        @action = :list
        case v
        when nil, /^o$/
          @state = :open
        when /^\d+$/
          @action = :show
          @number = v.to_i
        when /^c$/
          @state = :closed
        else
          @action = :search
          @state ||= :open
          @search_term = v
        end
      end

      opts.on("-o", "--open", "--reopen [number]") do |v|
        @action = :open
        case v
        when /^\d+$/
          @action = :reopen
          @number = v.to_i
        when /^l/, nil
          @action = :list
          @state = :open
        else
          @title = v
        end
      end

      opts.on("-c", "--closed", "--close [number]") do |v|
        case v
        when /^\d+$/
          @action = :close
          @number = v.to_i
        when /^l/, nil
          @action = :list
          @state = :closed
        else
          raise OptionParser::InvalidOption
        end
      end

      opts.on("-e", "--edit [number]") do |v|
        case v
        when /^\d+$/
          @action = :edit
          @state = :closed
          @number = v.to_i
        else
          raise OptionParser::MissingArgument
        end
      end

      opts.on("-r", "--repo", "--repository [name]") do |v|
        repo = v.split "/"
        repo.unshift GHI.login if repo.length == 1
        @user, @repo = repo
      end

      opts.on("-V", "--version") do
        puts "#{File.basename($0)}: v#{GHI::VERSION}"
        exit
      end

      opts.on("-h", "--help") do
        puts opts
        exit
      end
    }
  end

  def search(term, state)
    issues = api.search term, state
    puts "# #{state.to_s.capitalize} #{term.inspect} issues on #{user}/#{repo}"
    if issues.empty?
      puts "none"
    else
      puts issues.map { |i| "  #{i.number.to_s.rjust(3)}: #{i.title[0,72]}" }
    end
  end

  def list(state)
    issues = api.list state
    puts "# #{state.to_s.capitalize} issues on #{user}/#{repo}"
    if issues.empty?
      puts "none"
    else
      puts issues.map { |i| "  #{i.number.to_s.rjust(3)}: #{i.title[0,72]}" }
    end
  end

  def show(number)
    issue = api.show number
    puts <<-BODY
  #{issue.number}: #{issue.title} [#{issue.state}]

       votes:  #{issue.votes}
  created_at:  #{issue.created_at}
  updated_at:  #{issue.updated_at}

  #{issue.body}

  -- #{issue.user}
BODY
  end

  def open(title)
    edit = ENV["VISUAL"] || ENV["EDITOR"] || "vi"
    temp = Tempfile.open("open-issue-")
    temp.write <<-BODY
#{"#{title}\n" unless title.nil?}
# Please explain the issue. The first line will be used as the title.
# Lines with "#" will be ignored, and empty issues will not be filed.
# All line breaks will be honored in accordance with GFM:
#
#   http://github.github.com/github-flavored-markdown
#
# On #{user}/#{repo}:
#
#         user:  #{GHI.login}
  BODY
    temp.rewind
    system "#{edit} #{temp.path}"
    lines = File.readlines(temp.path).find_all { |l| !l.match(/^#/) }
    temp.close!
    if lines.to_s =~ /\A\s*\Z/
      warn "can't file empty issue"
      exit 1
    else
      title = lines.shift.strip
      body = lines.join.sub(/\b\n\b/, " ").strip
      issue = api.open title, body
      puts "  Opened issue #{issue.number}: #{issue.title[0,58]}"
    end
  end

  def edit(number)
    edit = ENV["VISUAL"] || ENV["EDITOR"] || "vi"
    begin
      temp = Tempfile.open("open-issue-")
      issue = api.show number
      temp.write <<-BODY
#{issue.title}#{"\n\n" + issue.body unless issue.body.to_s.strip == ""}
# Please explain the issue. The first line will be used as the title.
# Lines with "#" will be ignored, and empty issues will not be filed.
# All line breaks will be honored in accordance with GFM:
#
#   http://github.github.com/github-flavored-markdown
#
# On #@user/#@repo:
#
#       number:  #{issue.number}
#         user:  #{issue.user}
#        votes:  #{issue.votes}
#        state:  #{issue.state}
#   created at:  #{issue.created_at}
      BODY
      if issue.updated_at > issue.created_at
        temp.write "#   updated at:  #{issue.updated_at}"
      end
      temp.rewind
      system "#{edit} #{temp.path}"
      lines = File.readlines(temp.path)
      if temp.readlines == lines
        warn "no change"
        exit 1
      else
        lines.reject! { |l| l.match(/^#/) }
        if lines.to_s =~ /\A\s*\Z/
          warn "can't file empty issue"
          exit 1
        else
          title = lines.shift.strip
          body = lines.join.sub(/\b\n\b/, " ").strip
          issue = api.edit number, title, body
          puts "  Updated issue #{issue.number}: #{issue.title[0,58]}"
        end
      end
    ensure
      temp.close!
    end
  end

  def close(number)
    issue = api.close number
    puts "  Closed issue #{issue.number}: #{issue.title[0,58]}"
  end

  def reopen(number)
    issue = api.reopen number
    puts "  Reopened issue #{issue.number}: #{issue.title[0,56]}"
  end
end
