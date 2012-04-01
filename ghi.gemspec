$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'ghi/commands/version'

Gem::Specification.new do |s|
  s.name             = 'ghi'
  s.version          = GHI::Commands::Version::VERSION
  s.summary          = 'GitHub Issues command line interface'
  s.description      = <<EOF
GitHub Issues on the command line. Use your `$EDITOR`, not your browser.
EOF

  s.files            = Dir['lib/**/*']
  s.executables      = %w(ghi)

  s.has_rdoc         = true
  s.extra_rdoc_files = %w(README.markdown)
  s.rdoc_options     = %w(--main README.markdown)

  s.author           = 'Stephen Celis'
  s.email            = 'stephen@stephencelis.com'
  s.homepage         = 'https://github.com/stephencelis/ghi'
end
