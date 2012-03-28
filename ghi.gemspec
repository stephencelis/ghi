Gem::Specification.new do |s|
  s.name = "ghi"
  s.version = "0.3.2"
  s.summary = "GitHub Issues command line interface"
  s.description = "GitHub Issues on the command line. Use your `$EDITOR`, not your browser."

  s.files = ["bin/ghi", "lib/ghi/api.rb", "lib/ghi/cli.rb", "lib/ghi/issue.rb", "lib/ghi.rb", "spec/ghi/api_spec.rb", "spec/ghi/cli_spec.rb", "spec/ghi/issue_spec.rb", "spec/ghi_spec.rb"]
  s.executables = ["ghi"]
  s.default_executable = "ghi"

  s.add_development_dependency "rspec", "< 2.0"

  s.has_rdoc = true
  s.extra_rdoc_files = %w(README.rdoc)
  s.rdoc_options = %w(--main README.rdoc)

  s.author = "Stephen Celis"
  s.email = "stephen@stephencelis.com"
  s.homepage = "http://github.com/stephencelis/ghi"
end
