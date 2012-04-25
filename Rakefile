desc 'Build the standalone script'
task :build do
  manifest = %w(
    lib/ghi.rb
    lib/ghi/json.rb
    lib/ghi/formatting/colors.rb
    lib/ghi/formatting.rb
    lib/ghi/authorization.rb
    lib/ghi/client.rb
    lib/ghi/editor.rb
    lib/ghi/web.rb
    lib/ghi/commands.rb
    lib/ghi/commands/command.rb
    lib/ghi/commands/assign.rb
    lib/ghi/commands/close.rb
    lib/ghi/commands/comment.rb
    lib/ghi/commands/config.rb
    lib/ghi/commands/edit.rb
    lib/ghi/commands/help.rb
    lib/ghi/commands/label.rb
    lib/ghi/commands/list.rb
    lib/ghi/commands/milestone.rb
    lib/ghi/commands/open.rb
    lib/ghi/commands/show.rb
    lib/ghi/commands/version.rb
    bin/ghi
  )
  files = FileList[*manifest]
  File.open 'ghi', 'w' do |f|
    f.puts '#!/usr/bin/env ruby'
    f.puts '# encoding: utf-8'
    files.each { |file| f << File.read(file).gsub(/^\s+autoload.+$\n+/, '') }
    f.chmod 0755
  end
end

desc 'Install the standalone script'
task :install => :build do
  prefix = ENV['PREFIX'] || ENV['prefix'] || '/usr/local'
  FileUtils.mkdir_p   "#{prefix}/bin"
  FileUtils.cp 'ghi', "#{prefix}/bin"
end
