desc 'Build the standalone script'
task :build do
  manifest = %w(
    lib/ghi/commands/version.rb
    lib/ghi.rb
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
    lib/ghi/commands/disable.rb
    lib/ghi/commands/enable.rb
    lib/ghi/commands/help.rb
    lib/ghi/commands/label.rb
    lib/ghi/commands/list.rb
    lib/ghi/commands/lock.rb
    lib/ghi/commands/milestone.rb
    lib/ghi/commands/open.rb
    lib/ghi/commands/show.rb
    lib/ghi/commands/status.rb
    lib/ghi/commands/unlock.rb
    bin/ghi
  )
  files = FileList[*manifest]
  File.open 'ghi', 'w' do |f|
    f.puts '#!/usr/bin/env ruby'
    f.puts '# encoding: utf-8'
    files.each { |file| f << File.read(file).gsub(/^\s+autoload.+$\n+/, '') }
    f.chmod 0755
  end
  system './ghi 1>/dev/null'
	puts "ghi successfully built!"
end

desc 'Build the manuals'
task :man do
  `ronn man/*.ronn --manual='GHI Manual' --organization='Stephen Celis'`
end

desc 'Install the standalone script'
task :install => [:build, :man] do
  prefix = ENV['PREFIX'] || ENV['prefix'] || '/usr/local'

  FileUtils.mkdir_p   "#{prefix}/bin"
  FileUtils.cp 'ghi', "#{prefix}/bin"

  FileUtils.mkdir_p "#{prefix}/share/man/man1"
  FileUtils.cp Dir["man/*.1"], "#{prefix}/share/man/man1"
end
