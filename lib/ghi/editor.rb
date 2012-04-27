require 'tempfile'

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
  end
end
