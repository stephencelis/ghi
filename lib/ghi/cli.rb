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
      return @message if comment?
      return @message.shift.strip, @message.join.sub(/\b\n\b/, " ").strip
    end

    def delete_message
      File.delete message_path
    rescue Errno::ENOENT, TypeError
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
      @gitdir ||= `git rev-parse --git-dir`.chomp
    end

    def message_filename
      @message_filename ||= "GHI_#{action.to_s.upcase}#{number}_MESSAGE"
    end

    def file_proc(issue)
      lambda do |file|
        file << edit_format(issue).join("\n") if File.zero? message_path
        file.rewind
        launch_editor file
        @message = File.readlines(file.path).find_all { |l| !l.match(/^#/) }

        if message.to_s =~ /\A\s*\Z/
          raise GHI::API::InvalidRequest, "can't file empty message"
        end
        raise GHI::API::InvalidRequest, "no change" if issue == message
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
      l << issue.title if issue.title && !comment?
      l << ""
      l << issue.body  if issue.body  && !comment?
      if comment?
        l << "# Please enter your comment."
      else
        l << "# Please explain the issue. The first line will become the title."
      end
      l << "# Lines beginning '#' will be ignored; ghi aborts empty messages."
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
      l += indent(issue.body)[0..-2]
    end

    def action_format(value = nil)
      key = "#{action.to_s.capitalize.sub(/e?$/, "ed")} issue #{number}"
      "#{key}: #{truncate value.to_s, 78 - key.length}"
    end

    def truncate(string, length)
      result = string.scan(/.{0,#{length}}(?:\s|\Z)/).first.strip
      result << "..." if result != string
      result
    end

    def indent(string, level = 4)
      string.scan(/.{0,#{78 - level}}(?:\s|\Z)/).map { |line|
        " " * level + line
      }
    end

    private

    def comment?
      ![:open, :edit].include?(action)
    end
  end

  class Executable
    include FileHelper, FormattingHelper

    attr_reader :message, :user, :repo, :api, :action, :state, :search_term,
      :number, :title, :body, :label, :args

    def initialize(*args)
      @args = option_parser.parse!(*args)

      if action.nil?
        puts option_parser
        exit
      end

      `git config --get remote.origin.url`.match %r{([^:/]+)/([^/]+).git$}
      @user ||= $1
      @repo ||= $2
      @api = GHI::API.new user, repo
    end

    def run!
      case action
        when :search        then search
        when :list          then list
        when :show          then show
        when :open          then open
        when :edit          then edit
        when :close         then close
        when :reopen        then reopen
        when :comment       then comment
        when :label, :claim then add_label
        when :unlabel       then remove_label

        when :url           then url
      end
    rescue GHI::API::InvalidConnection
      warn "#{File.basename $0}: not a GitHub repo"
      exit 1
    rescue GHI::API::InvalidRequest => e
      warn "#{File.basename $0}: #{e.message} (#{user}/#{repo})"
      delete_message
      exit 1
    rescue GHI::API::ResponseError => e
      warn "#{File.basename $0}: #{e.message} (#{user}/#{repo})"
      exit 1
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument,
        OptionParser::AmbiguousOption => e
      warn "#{File.basename $0}: #{e.message}"
      exit 1
    end

    private

    def option_parser
      @option_parser ||= OptionParser.new { |opts|
        opts.banner = "Usage: #{File.basename $0} [options]"

        opts.on("-l", "--list", "--search", "--show [state|term|number]") do |v|
          @action = :list
          case v
          when nil, /^o(?:pen)?$/
            @state = :open
          when /^\d+$/
            @action = :show
            @number = v.to_i
          when /^c(?:losed)?$/
            @state = :closed
          when /^u$/
            @action = :url
          else
            @action = :search
            @state ||= :open
            @search_term = v
          end
        end

        opts.on("-o", "--open", "--reopen [title|number]") do |v|
          @action = :open
          case v
          when /^\d+$/
            @action = :reopen
            @number = v.to_i
          when /^l$/
            @action = :list
            @state = :open
          when /^m$/
            @title = ARGV * " "
          when /^u$/
            @action = :url
          else
            @title = v
          end
        end

        opts.on("-c", "--closed", "--close [number]") do |v|
          case v
          when /^\d+$/
            @action ||= :close
            @number = v.to_i unless v.nil?
          when /^l$/, nil
            @action = :list
            @state = :closed
          when /^u$/, nil
            @action = :url
            @state = :closed
          when nil
            raise OptionParser::MissingArgument
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
          when nil
            raise OptionParser::MissingArgument
          else
            raise OptionParser::InvalidOption
          end
        end

        opts.on("-r", "--repo", "--repository [name]") do |v|
          repo = v.split "/"
          repo.unshift GHI.login if repo.length == 1
          @user, @repo = repo
        end

        opts.on("-m", "--comment [number|comment]") do |v|
          case v
          when /^\d+$/, nil
            @action ||= :comment
            @number ||= v
            @comment = true
          else
            @body = v
          end
        end

        opts.on("-t", "--label [number] [label]") do |v|
          raise OptionParser::MissingArgument if v.nil?
          @action ||= :label
          @number = v.to_i
        end

        opts.on("--claim [number]") do |v|
          raise OptionParser::MissingArgument if v.nil?
          @action = :claim
          @number = v.to_i
          @label = GHI.login
        end

        opts.on("-d", "--unlabel [number] [label]") do |v|
          @action = :unlabel
          case v
          when /^\d+$/
            @number = v.to_i
          when /^\w+$/
            @label = v
          end
        end

        opts.on("-u", "--url [number]") do |v|
          @action = :url
          case v
          when /^\d+$/
            @number = v.to_i
          when /^c/
            @state = :closed
          end
        end

        opts.on_tail("-V", "--version") do
          puts "#{File.basename($0)}: v#{GHI::VERSION}"
          exit
        end

        opts.on_tail("-h", "--help") do
          puts opts
          exit
        end
      }
    end

    def search
      issues = api.search search_term, state
      puts list_format(issues, search_term)
    end

    def list
      issues = api.list state
      puts list_format(issues)
    end

    def show
      issue = api.show number
      puts show_format(issue)
    end

    def open
      if title.nil?
        new_title, new_body = gets_from_editor GHI::Issue.new("title" => body)
      elsif @comment && body.nil?
        new_title, new_body = gets_from_editor GHI::Issue.new("title" => title)
      end
      new_title ||= title
      new_body  ||= body
      issue = api.open new_title, new_body
      delete_message
      @number = issue.number
      puts action_format(issue.title)
    end

    def edit
      shown = api.show number
      new_title, new_body = gets_from_editor(shown) if body.nil?
      new_title ||= shown.title
      new_body  ||= body
      issue = api.edit number, new_title, new_body
      delete_message
      puts action_format(issue.title)
    end

    def close
      issue = api.close number
      if @comment || new_body = body
        new_body ||= gets_from_editor issue
        comment = api.comment number, new_body
      end
      puts action_format(issue.title)
      puts "(comment #{comment["status"]})" if comment
    end

    def reopen
      issue = api.reopen number
      if @comment || new_body = body
        new_body ||= gets_from_editor issue
        comment = api.comment number, new_body
      end
      puts action_format(issue.title)
      puts "(comment #{comment["status"]})" if comment
    end

    def add_label
      new_label = label || body || @args * " "
      labels = api.add_label new_label, number
      puts action_format
      puts indent(labels.join(", "))
    end

    def remove_label
      new_label = label || body || @args * " "
      labels = api.remove_label new_label, number
      puts action_format
      puts indent(labels.empty? ? "no labels" : labels.join(", "))
    end

    def comment
      body = gets_from_editor api.show(number)
      comment = api.comment(number, body)
      delete_message
      puts "(comment #{comment["status"]})"
    end

    def url
      url = "http://github.com/#{user}/#{repo}/issues"
      url << "/#{state}"       unless state.nil?
      url << "/#{number}/find" unless number.nil?
      puts url
    end
  end
end
