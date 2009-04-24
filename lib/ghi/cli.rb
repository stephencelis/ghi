require "optparse"
require "tempfile"
require "ghi"
require "ghi/api"
require "ghi/issue"

module GHI::CLI #:nodoc:
  module FileHelper
    def launch_editor(file)
      system "#{editor} #{file.path}"
    end

    def gets_from_editor(issue)
      if gitdir
        File.open message_path, "a+", &file_proc(issue)
      else
        Tempfile.new message_filename, &file_proc(issue)
      end
      return @message.shift.strip, @message.join.sub(/\b\n\b/, " ").strip
    end

    def delete_message
      File.delete message_path
    rescue TypeError
      nil
    end

    def message_path
      File.join gitdir, message_filename
    end

    private

    def editor
      ENV["VISUAL"] || ENV["EDITOR"] || "vi"
    end

    def gitdir
      @gitdir ||= begin
        dirs = []
        Dir.pwd.count("/").times { |n| dirs << ([".."] * n << ".git") * "/" }
        Dir[*dirs].first
      end
    end

    def message_filename
      @message_filename ||= "GHI_#{action.to_s.upcase}_MESSAGE"
    end

    def file_proc(issue)
      lambda do |file|
        file << edit_format(issue).join("\n") if File.zero? message_path
        file.rewind
        launch_editor file
        lines = File.readlines file.path
        @message = lines.find_all { |l| !l.match(/^#/) }
        raise "can't file empty issue" if message.to_s =~ /\A\s*\Z/
        raise "no change"              if file.readlines == lines
      end
    end
  end

  module FormattingHelper
    def list_format(issues, term = nil)
      l = if term
        ["# #{state.to_s.capitalize} #{term.inspect} issues on #{user}/#{repo}"]
      else
        ["# #{state.to_s.capitalize} issues on #{user}/#{repo}"]
      end

      l += unless issues.empty?
        issues.map { |i| "  #{i.number.to_s.rjust 3}: #{truncate i.title, 72}" }
      else
        ["none"]
      end
    end

    def edit_format(issue)
      l = []
      l << issue.title                          if issue.title
      l << ""
      l << issue.body                           if issue.body
      l << "# Please explain the issue. The first line will become the title."
      l << "# Lines beginning '#' will be ignored. Empty issues won't be filed."
      l << "# All line breaks will be honored in accordance with GFM:"
      l << "#"
      l << "#   http://github.github.com/github-flavored-markdown"
      l << "#"
      l << "# On #{user}/#{repo}:"
      l << "#"
      l += show_format(issue, false).map { |line| "# #{line}" }
    end

    def show_format(issue, verbose = true)
      l = []
      l << "      number:  #{issue.number}"     if issue.number
      l << "       state:  #{issue.state}"      if issue.state
      l << "       title:  #{issue.title}"      if issue.title
      l << "        user:  #{issue.user || GHI.login}"
      l << "       votes:  #{issue.votes}"      if issue.votes
      l << "  created at:  #{issue.created_at}" if issue.created_at
      l << "  updated at:  #{issue.updated_at}" if issue.updated_at
      return l unless verbose
      l << ""
      l += issue.body.scan(/.{0,75}(?:\s|$)/).map { |line| "    #{line}" }
    end

    def action_format(issue)
      key = "#{action.to_s.capitalize.sub(/e?$/, "ed")} issue #{issue.number}"
      "#{key}: #{truncate issue.title, 78 - key.length}"
    end

    def truncate(string, length)
      result = string.scan(/.{0,#{length}}(?:\s|$)/).first.strip
      result << "..." if result != string
      result
    end
  end

  class Executable
    include FileHelper, FormattingHelper

    attr_reader :message, :user, :repo, :api, :action, :state, :number, :title,
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
      exit 1
    rescue GHI::API::ResponseError => e
      warn "#{File.basename $0}: #{e.message} (#{user}/#{repo})"
      exit 1
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      warn "#{File.basename $0}: #{e.message}"
      exit 1
    rescue StandardError => e
      warn e.message
      exit 1
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
          when /^l$/
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
      puts list_format(issues, term)
    end

    def list(state)
      issues = api.list state
      puts list_format(issues)
    end

    def show(number)
      issue = api.show number
      puts show_format(issue)
    end

    def open(title)
      title, body = gets_from_editor GHI::Issue.new(:title => title)
      issue = api.open title, body
      delete_message
      puts action_format(issue)
    end

    def edit(number)
      title, body = gets_from_editor api.show(number)
      issue = api.edit number, title, body
      delete_message
      puts action_format(issue)
    end

    def close(number)
      issue = api.close number
      puts action_format(issue)
    end

    def reopen(number)
      issue = api.reopen number
      puts action_format(issue)
    end
  end
end
