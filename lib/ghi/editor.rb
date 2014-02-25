require 'tmpdir'

module GHI
  class Editor
    attr_reader :filename
    def initialize filename
      @filename = filename
    end

    def gets prefill
      File.open path, 'a+' do |f|
        f << prefill if File.zero? path
        f.rewind
        system "#{editor} #{f.path}"
        return File.read(f.path).gsub(/(?:^\s*\<\!--.*--\>\s*$\n?)+\s*\z/, '').strip
      end
    end

    def unlink message = nil
      File.delete path
      abort message if message
    end

    private

    def editor
      editor   = GHI.config 'ghi.editor'
      editor ||= GHI.config 'core.editor'
      editor ||= ENV['VISUAL']
      editor ||= ENV['EDITOR']
      editor ||= 'vi'
    end

    def path
      File.join dir, filename
    end

    def dir
      @dir ||= git_dir || Dir.tmpdir
    end

    def git_dir
      return unless Commands::Command.detected_repo
      dir = `git rev-parse --git-dir 2>/dev/null`.chomp
      dir unless dir.empty?
    end

    # Possibly new editor interface
    #
    # Currently only used by the pull command, but could be the base
    # for a bigger refactoring. Adds flexibility.
    public

    def start(template = '')
      File.open path, 'a+' do |f|
        f << template if File.zero? path
        f.rewind
        system "#{editor} #{f.path}"
        parse(f.path)
      end
    end

    # TODO
    # allow a hash here as well:
    #   key: what's required
    #   val: custom error message as string or proc
    def require_content_for(*contents)
      guarded do
        contents.each do |c|
          unless content[c] && ! content[c].empty?
            raise "#{c.capitalize} must not be empty!"
          end
        end
      end
    end

    def check_uniqueness(a, b)
      guarded do
        x, y = content.values_at(a, b)
        raise "#{a} must not be the same as #{b}" if x == y
      end
    end

    def check_for_changes(old)
      if old.all? { |keyword, old_content| content[keyword] == old_content }
        unlink "Nothing changed."
      end
    end

    def content
      @content ||= {}
    end

    # New comments need a special format:
    #
    # @
    # Comment we want to add
    # @
    #
    # The comment body needs to surrounded by a single @ on a new line. No
    # whitespace before or after!
    # Just place your body right behind the line you want to comment.
    #
    # The API wants to know
    # - the file the comment is on. (path)
    # - line position inside the changes of a particular file.(position)
    # - a message of course (body)
    # - the head's sha (commit_id) - added later on in the Pull subclass.
    #
    # We split the diff into individual files and retrieve these parts
    # in a Hash (key: filename, value: diff).
    # We go through each diff then and look for comments. All findings
    # are saved into Hash objects, an array of these is the return value
    # of this method.
    def extract_new_comments
      marker = /^@$/
      txt = content[:body]
      unlink "No new comments present." unless txt.match(marker)

      result = []
      diff_per_file = split_diff_per_file(txt)
      diff_per_file.map do |file, diff|
        while index = diff =~ marker
          comment = { 'path' => file }
          # The marker itself and its \n is included, therefore
          # we need the index - 1
          # The position is also zero based - count - 1 sets this right.
          comment['position'] = diff[0..index - 2].lines.count - 1
          if diff.sub!(/^@\n(.*?)^@$/m) { comment['body'] = $1.strip; '' }
            result << comment
          else
            raise "Invalid comment format present!"
          end
        end
      end
      result
    end

    private

    def split_diff_per_file(txt)
      parts = txt.split(/^diff --git a\/.* b\/.*?\n/).delete_if(&:empty?)
      # Throw out the rest of the diff information, but extract the
      # relative path to the file we might comment one
      parts.map! { |part| [part.sub(/.*--- .*\n\+\+\+ b\/(.*?)\n/m, ''), $1].reverse }
      Hash[parts]
    end

    def guarded
      begin
        yield
      rescue => e
        puts e
        print "Type e to enter your editor again, any other key discards your input and aborts: "
        if $stdin.gets.chomp == 'e'
          start
          retry
        else
          unlink "Aborted."
        end
      end
    end

    def parse(file)
      txt = File.read(file)
      strip_lines_to_ignore(txt)
      extract_keywords(txt, :title, :head, :base)
      content[:body] = txt.strip
    end

    def extract_keywords(txt, *keywords)
      keywords.each do |kw|
        extract_keyword(txt, kw)
      end
    end

    def extract_keyword(txt, kw, array = false)
      return unless txt.sub!(/^@ghi-#{kw}@(.*)(\n|$)/, '')
      val = $1.strip
      val = val.split(', ') if array
      content[kw] = val
    end

    def strip_lines_to_ignore(txt)
      txt.gsub!(/^#{Regexp.quote(IGNORE_MARKER)}.*(\n|\z)/, '')
      # The next line is kept for backwards compatibility
      txt.gsub!(/(?:^#.*$\n?)+\s*\z/, '')
      txt.strip!
    end
  end
end
