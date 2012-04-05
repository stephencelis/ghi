require 'tempfile'

module GHI
  class Editor
    class << self
      def gets prefill
        Tempfile.open 'GHI_ISSUE' do |f|
          f << prefill
          f.rewind
          system "#{editor} #{f.path}"
          return File.read(f.path).gsub(/^#.*$\n?/, '').strip
        end
      end

      private

      def editor
        editor   = ENV['GHI_EDITOR']
        editor ||= ENV['GIT_EDITOR']
        editor ||= `git config core.editor`.split.first
        editor ||= ENV['EDITOR']
        editor ||= 'vi'
      end
    end
  end
end
