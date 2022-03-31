$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'ghi/commands/version'

Gem::Specification.new do |s|
  s.name             = 'ghi'
  s.version          = GHI::Commands::Version::VERSION
  s.license          = 'MIT'
  s.summary          = 'GitHub Issues command line interface'
  s.description      = <<EOF
GitHub Issues on the command line. Use your `$EDITOR`, not your browser.
EOF

  s.files            = Dir['lib/**/*']
  s.executables      = %w(ghi)

  s.has_rdoc         = false

  s.author           = 'Stephen Celis'
  s.email            = 'stephen@stephencelis.com'
  s.homepage         = 'https://github.com/stephencelis/ghi'

  s.add_runtime_dependency 'pygments.rb'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'ronn'
  s.add_development_dependency 'typhoeus'
  s.add_development_dependency 'single_test'
end
