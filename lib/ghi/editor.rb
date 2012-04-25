require 'tempfile'

module GHI
  class Editor
    class << self
      def gets prefill
        Tempfile.open 'GHI_ISSUE' do |f|
          f << prefill
          f.rewind
          system "#{editor} #{f.path}"
          return File.read(f.path).gsub(/(?:^#.*$\n?)+\s*\z/, '').strip
        end
      end

      private

      def editor
        editor   = GHI.config 'ghi.editor'
        editor ||= GHI.config 'core.editor'
        editor ||= ENV['VISUAL']
        editor ||= ENV['EDITOR']
        editor ||= 'vi'
      end
    end
  end
end
