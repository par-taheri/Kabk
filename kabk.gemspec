# frozen_string_literal: true

require_relative "lib/kabk/version"

Gem::Specification.new do |spec|
  spec.name          = "kabk"
  spec.version       = Kabk::VERSION
  spec.authors       = ["Parham Taheri"]
  spec.email         = ["Par_taheri@yahoo.com"]
  spec.license       = "MIT"

  spec.summary       = "Core engine for Schema-Driven Dynamic Admin Specification (Protocol v1.6.0)."
  spec.description   = "Framework-agnostic engine that provides resource registration, JSON schema manifest generation, generic CRUD engine, server-side validation, and relation hydration."
  spec.homepage      = "https://github.com/par-taheri/Kabk"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/par-taheri/Kabk"
  spec.metadata["changelog_uri"] = "https://github.com/par-taheri/Kabk/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob("**/*").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)}) || f.end_with?(".gem")
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "concurrent-ruby", "~> 1.1"
  spec.add_dependency "sequel", "~> 5.0"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "webrick"
  spec.add_development_dependency "rubocop", "~> 1.21"
end
