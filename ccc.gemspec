require_relative "lib/ccc/version"

Gem::Specification.new do |spec|
  spec.name = "ccc"
  spec.version = Ccc::VERSION
  spec.authors = ["Frampt"]
  spec.email = ["18995691365@189.cn"]
  spec.summary = "Coding Ciphering and Crypto"
  spec.description = "A Ruby gem for coding, ciphering, and cryptography utilities."
  spec.homepage = "https://github.com/ChenMeng1365/ccc"
  spec.license = "AGPL-3.0-or-later"
  spec.required_ruby_version = ">= 2.7.0"

  # Prevent pushing this gem to RubyGems.org by mistake
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ChenMeng1365/ccc"
  spec.metadata["changelog_uri"] = "https://github.com/ChenMeng1365/ccc/blob/main/CHANGELOG.md"

  # Files included in the gem (git-independent fallback)
  spec.files = Dir["lib/**/*.rb"] + ["README.md", "LICENSE"]
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Pure stdlib; no runtime dependencies
  # spec.add_dependency "example", "~> 1.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
end
