# frozen_string_literal: true

require_relative "lib/ruby_maat/version"

Gem::Specification.new do |spec|
  spec.name = "ruby-maat"
  spec.version = RubyMaat::VERSION
  spec.authors = ["Adam Tornhill", "Claude Code", "Bart Agapinan"]
  spec.email = ["bart@sonic.net"]

  spec.summary = "A command line tool used to mine and analyze data from version-control systems"
  spec.description = "Ruby Maat is a command line tool used to mine and analyze data from version-control " \
                     "systems (VCS). This is a Ruby port of the original Clojure Code Maat."
  spec.homepage = "https://github.com/viamin/ruby-maat"
  spec.license = "GPL-3.0"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/viamin/ruby-maat"
  spec.metadata["changelog_uri"] = "https://github.com/viamin/ruby-maat/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "csv", "~> 3.2"
  spec.add_dependency "rexml", "~> 3.2"
  spec.add_dependency "rover-df", "~> 0.3"
end
