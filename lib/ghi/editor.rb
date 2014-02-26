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
        return File.read(f.path).gsub(/(?:^#.*$\n?)+\s*\z/, '').strip
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

    def start(template)
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
    #   val: error message as string or proc
    def require_content_for(*contents)
      contents.each do |c|
        unless content[c] && ! content[c].empty?
          abort "#{c.capitalize} must not be empty!"
        end
      end
    end

    def check_uniqueness(a, b)
      x, y = content.values_at(a, b)
      abort "#{a} must not be the same as #{b}" if x == y
    end

    def content
      @content ||= {}
    end

    private

    def parse(file)
      txt = File.read(file)
      strip_explanation_lines(txt)
      extract_keywords(txt, :title, :head, :base)
      content[:body] = txt.strip
    end

    def extract_keywords(txt, *keywords)
      keywords.each do |kw|
        extract_keyword(txt, kw)
      end
    end

    def extract_keyword(txt, kw, array = false)
      txt.sub!(/^@ghi-#{kw}@(.*)(\n|$)/, '')
      val = $1.to_s.strip
      val = val.split(', ') if array
      content[kw] = val
    end

    def strip_explanation_lines(txt)
      txt.gsub!(/(?:^#.*$\n?)+\s*\z/, '')
      txt.strip!
    end
  end
end
