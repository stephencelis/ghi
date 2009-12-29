require "optparse"
require "tempfile"
require "ghi"
require "ghi/api"
require "ghi/issue"

begin
  require "launchy"
rescue LoadError
  # No launchy!
end

module GHI::CLI #:nodoc:
  module FileHelper
    def launch_editor(file)
      system "#{editor} #{file.path}"
    end

    def gets_from_editor(issue)
      if windows?
        warn "Please supply the message with the -m option"
        exit 1
      end

      if in_repo?
        File.open message_path, "a+", &file_proc(issue)
      else
        Tempfile.open message_filename, &file_proc(issue)
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
      ENV["GHI_EDITOR"] || ENV["GIT_EDITOR"] ||
        `git config --get-all core.editor`.split.first || ENV["EDITOR"] || "vi"
    end

    def gitdir
      @gitdir ||= `git rev-parse --git-dir 2>/dev/null`.chomp
    end

    def message_filename
      @message_filename ||= "GHI_#{action.to_s.upcase}#{number}_MESSAGE"
    end

    def file_proc(issue)
      lambda do |file|
        file << edit_format(issue).join("\n") if File.zero? file.path
        file.rewind
        launch_editor file
        @message = File.readlines(file.path).find_all { |l| !l.match(/^#/) }

        if message.to_s =~ /\A\s*\Z/
          raise GHI::API::InvalidRequest, "can't file empty message"
        end
        raise GHI::API::InvalidRequest, "no change" if issue == message
      end
    end

    def in_repo?
      !gitdir.empty? && user == local_user && repo == local_repo
    end
  end

  module FormattingHelper
    def list_header(term = nil)
      if term
        "# #{state.to_s.capitalize} #{term.inspect} issues on #{user}/#{repo}"
      else
        "# #{state.to_s.capitalize} issues on #{user}/#{repo}"
      end
    end

    def list_format(issues, verbosity = nil)
      unless issues.empty?
        if verbosity
          issues.map { |i| ["=" * 79] + show_format(i) }
        else
          issues.map { |i| "  #{i.number.to_s.rjust 3}: #{truncate(i.title, 72)}" }
        end
      else
        "none"
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
      l << "      number:  #{issue.number}"                    if issue.number
      l << "       state:  #{issue.state}"                     if issue.state
      l << "       title:  #{indent(issue.title, 15, 0).join}" if issue.title
      l << "        user:  #{issue.user || GHI.login}"
      l << "       votes:  #{issue.votes}"                     if issue.votes
      l << "  created at:  #{issue.created_at}"                if issue.created_at
      l << "  updated at:  #{issue.updated_at}"                if issue.updated_at
      return l unless verbose
      l << ""
      l += indent(issue.body)[0..-2]
    end

    def action_format(value = nil)
      key = "#{action.to_s.capitalize.sub(/e?$/, "ed")} issue #{number}"
      "#{key}: #{truncate(value.to_s, 78 - key.length)}"
    end

    def truncate(string, length)
      result = string.scan(/.{0,#{length - 3}}(?:\s|\Z)/).first.strip
      result << "..." if result != string
      result
    end

    def indent(string, level = 4, first = level)
      lines = string.scan(/.{0,#{79 - level}}(?:\s|\Z)/).map { |line|
        " " * level + line
      }
      lines.first.sub!(/^\s+/) {} if first != level
      lines
    end

    private

    def comment?
      ![:open, :edit].include?(action)
    end

    def puts(*args)
      args = args.flatten.each { |arg|
        arg.gsub!(/\b\*(.+)\*\b/) { "\e[1m#$1\e[0m" } # Bold
        arg.gsub!(/\b_(.+)_\b/) { "\e[4m#$1\e[0m" } # Underline
        arg.gsub!(/(state:)?(# Open.*|  open)$/) { "#$1\e[32m#$2\e[0m" }
        arg.gsub!(/(state:)?(# Closed.*|  closed)$/) { "#$1\e[31m#$2\e[0m" }
        marked = [GHI.login, search_term, tag, "(?:#|gh)-\d+"].compact * "|"
        unless arg.include? "\e"
          arg.gsub!(/(#{marked})/i) { "\e[1;4;33m#{$&}\e[0m" }
        end
      } if colorize?
    rescue NoMethodError
      # Do nothing.
    ensure
      $stdout.puts(*args)
    end

    def colorize?
      return @colorize if defined? @colorize
      @colorize = if $stdout.isatty && !windows?
        !`git config --get-regexp color`.chomp.empty?
      else
        false
      end
    end

    def prepare_stdout
      return if @prepared || @no_pager || !$stdout.isatty || pager.nil?
      colorize? # Check for colorization.
      $stdout = pager
      @prepared = true
    end

    def pager
      return @pager if defined? @pager
      pager = ENV["GHI_PAGER"] || ENV["GIT_PAGER"] ||
        `git config --get-all core.pager`.split.first || ENV["PAGER"] ||
        "less -EMRX"

      @pager = IO.popen(pager, "w")
    end

    def windows?
      RUBY_PLATFORM.include? "mswin"
    end
  end

  class Executable
    include FileHelper, FormattingHelper

    attr_reader :message, :local_user, :local_repo, :user, :repo, :api,
      :action, :search_term, :number, :title, :body, :tag, :args, :verbosity

    def parse!(*argv)
      @args, @argv = argv, argv.dup

      remotes = `git config --get-regexp remote\..+\.url`.split /\n/
      repo_expression = %r{([^:/]+)/([^/\s]+)(?:\.git)$}
      if remote = remotes.find { |r| r.include? "github.com" }
        remote.match repo_expression
        @user, @repo = $1, $2
      end

      option_parser.parse!(*args)

      if action.nil? && fallback_parsing(*args).nil?
        puts option_parser
        exit
      end
    rescue OptionParser::InvalidOption, OptionParser::InvalidArgument => e
      if fallback_parsing(*e.args).nil?
        warn "#{File.basename $0}: #{e.message}"
        puts option_parser
        exit 1
      end
    rescue OptionParser::MissingArgument, OptionParser::AmbiguousOption => e
      warn "#{File.basename $0}: #{e.message}"
      puts option_parser
      exit 1
    ensure
      run!
      $stdout.close_write
    end

    def run!
      @api = GHI::API.new user, repo

      case action
        when :search        then search
        when :list          then list
        when :show          then show
        when :open          then open
        when :edit          then edit
        when :close         then close
        when :reopen        then reopen
        when :comment       then prepare_comment && comment
        when :label, :claim then prepare_label   && label
        when :unlabel       then prepare_label   && unlabel
        when :url           then url
      end
    rescue GHI::API::InvalidConnection
      if action
        code = 1
        warn "#{File.basename $0}: not a GitHub repo"
        puts option_parser if args.flatten.empty?
        exit 1
      end
    rescue GHI::API::InvalidRequest => e
      warn "#{File.basename $0}: #{e.message} (#{user}/#{repo})"
      delete_message
      exit 1
    rescue GHI::API::ResponseError => e
      warn "#{File.basename $0}: #{e.message} (#{user}/#{repo})"
      exit 1
    end

    def commenting?
      @commenting
    end

    def state
      @state || :open
    end

    private

    def option_parser
      @option_parser ||= OptionParser.new { |opts|
        opts.banner = "Usage: #{File.basename $0} [options]"

        opts.on("-l", "--list", "--search", "--show [state|term|number]") do |v|
          @action = :list
          case v
          when nil, /^o(?:pen)?$/
            # Defaults.
          when /^\d+$/
            @action = :show
            @number = v.to_i
          when /^c(?:losed)?$/
            @state = :closed
          when /^[uw]$/
            @action = :url
          when /^v$/
            @verbosity = true
          else
            @action = :search
            @search_term = v
          end
        end

        opts.on("-v", "--verbose") do |v|
          if v
            @action ||= :list
            @verbosity = true
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
          when /^m$/
            @title = args * " "
          when /^[uw]$/
            @action = :url
          else
            @title = v
          end
        end

        opts.on("-c", "--closed", "--close [number]") do |v|
          case v
          when /^\d+$/
            @action = :close
            @number = v.to_i unless v.nil?
          when /^l$/
            @action = :list
            @state = :closed
          when /^[uw]$/
            @action = :url
            @state = :closed
          when nil
            if @action.nil? || @number
              @action = :close
            else
              @state = :closed
            end
          else
            raise OptionParser::InvalidArgument
          end
        end

        opts.on("-e", "--edit [number]") do |v|
          case v
          when /^\d+$/
            @action = :edit
            @number = v.to_i
          when nil
            raise OptionParser::MissingArgument
          else
            raise OptionParser::InvalidArgument
          end
        end

        opts.on("-r", "--repo", "--repository [name]") do |v|
          case v
          when nil
            raise OptionParser::MissingArgument
          else
            repo = v.split "/"
            if repo.length == 1
              if @repo && `git remote 2>/dev/null`[/^#{repo}$/]
                repo << @repo
              else
                repo.unshift(GHI.login)
              end
            end
            @user, @repo = repo
          end
        end

        opts.on("-m", "--comment [number|comment]") do |v|
          case v
          when /^\d+$/, nil
            @action ||= :comment
            @number ||= v.to_i unless v.nil?
            @commenting = true
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
          @tag = GHI.login
        end

        opts.on("-d", "--unlabel [number] [label]") do |v|
          @action = :unlabel
          case v
          when /^\d+$/
            @number = v.to_i
          when /^\w+$/
            @tag = v
          end
        end

        opts.on("-u", "-w", "--url", "--web [state|number]") do |v|
          @action = :url
          case v
          when /^\d+$/
            @number = v.to_i
          when /^c(?:losed)?$/
            @state = :closed
          when /^u(?:nread)?$/
            @state = :unread
          end
        end

        opts.on("--[no-]color") do |v|
          @colorize = v
        end

        opts.on("--[no-]pager") do |v|
          @no_pager = (v == false)
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
      prepare_stdout
      puts list_header(search_term)
      issues = api.search search_term, state
      puts list_format(issues, verbosity)
    end

    def list
      prepare_stdout
      puts list_header
      issues = api.list(state)
      puts list_format(issues, verbosity)
    end

    def show
      prepare_stdout
      issue = api.show number
      puts show_format(issue)
    end

    def open
      if title.nil?
        new_title, new_body = gets_from_editor GHI::Issue.new("title" => body)
      elsif @commenting && body.nil?
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
      raise GHI::API::InvalidRequest, "need a number" if number.nil?
      issue = api.close number
      if @commenting || new_body = body
        new_body ||= gets_from_editor issue
        comment = api.comment number, new_body
      end
      puts action_format(issue.title)
      puts "(comment #{comment["status"]})" if comment
    end

    def reopen
      issue = api.reopen number
      if @commenting || new_body = body
        new_body ||= gets_from_editor issue
        comment = api.comment number, new_body
      end
      puts action_format(issue.title)
      puts "(comment #{comment["status"]})" if comment
    end

    def prepare_label
      @tag ||= (body || args * " ")
      raise GHI::API::InvalidRequest, "need a label" if @tag.empty?
      true
    end

    def label
      labels = api.add_label tag, number
      puts action_format
      puts indent(labels.join(", "))
    end

    def unlabel
      labels = api.remove_label tag, number
      puts action_format
      puts indent(labels.empty? ? "no labels" : labels.join(", "))
    end

    def prepare_comment
      @body = args.flatten.first
      @commenting = false unless body.nil?
      true
    end

    def comment
      @body ||= gets_from_editor api.show(number)
      comment = api.comment(number, body)
      delete_message
      puts "(comment #{comment["status"]})"
    end

    def url
      url = "http://github.com/#{user}/#{repo}/issues"
      if number.nil?
        url << "/#{state}" unless state == :open
      else
        url << "#issue/#{number}"
      end
      defined?(Launchy) ? Launchy.open(url) : puts(url)
    end

    #-
    # Because these are mere fallbacks, any options used earlier will muddle
    # things: `ghi list` will work, `ghi list -c` will not.
    #
    # Argument parsing will have to better integrate with option parsing to
    # overcome this.
    #+
    def fallback_parsing(*arguments)
      arguments = arguments.flatten
      case command = arguments.shift
      when nil, "list"
        @action = :list
        if arg = arguments.shift
          @state ||= arg.to_sym if %w(open closed).include? arg
          @user, @repo = arg.split "/" if arg.count("/") == 1
        end
      when "search"
        @action = :search
        @search_term ||= arguments.shift
      when "show", /^-?(\d+)$/
        @action = :show
        @number ||= ($1 || arguments.shift[/\d+/]).to_i
      when "open"
        @action = :open
      when "edit"
        @action = :edit
        @number ||= arguments.shift[/\d+/].to_i
      when "close"
        @action = :close
        @number ||= arguments.shift[/\d+/].to_i
      when "reopen"
        @action = :reopen
        @number ||= arguments.shift[/\d+/].to_i
      when "label"
        @action = :label
        @number ||= arguments.shift[/\d+/].to_i
        @label ||= arguments.shift
      when "unlabel"
        @action = :unlabel
        @number ||= arguments.shift[/\d+/].to_i
        @label ||= arguments.shift
      when "comment"
        @action = :comment
        @number ||= arguments.shift[/\d+/].to_i
      when "claim"
        @action = :claim
        @number ||= arguments.shift[/\d+/].to_i
      when %r{^([^/]+)/([^/]+)$}
        @action = :list
        @user, @repo = $1, $2
      when "url", "web"
        @action = :url
        @number ||= arguments.shift[/\d+/].to_i
      end
      if @action
        @args = @argv.dup
        args.delete_if { |arg| arg == command }
        option_parser.parse!(*args)
        return true
      end
      unless command.start_with? "-"
        warn "#{File.basename $0}: what do you mean, '#{command}'?"
      end
    end
  end
end
