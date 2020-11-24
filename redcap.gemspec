require_relative 'lib/redcap/version'

Gem::Specification.new do |spec|
  spec.name          = "redcap-api"
  spec.version       = RedCAP::VERSION
  spec.authors       = ["Chris Ortman"]
  spec.email         = ["chris-ortman@uiowa.edu"]

  spec.summary       = %q{Integration library for RedCAP}
  spec.description   = %q{Uses the RedCAP API}
  spec.homepage      = "https://github.com/chrisortman/redcap-ruby.git"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/chrisortman/redcap-ruby.git"
  spec.metadata["changelog_uri"] = "https://github.com/chrisortman/redcap-ruby/changelog.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency('faraday', '~> 1.1')
  spec.add_dependency('activesupport', '>= 5.2')
  spec.add_dependency('zeitwerk', '>= 2.0')
end
