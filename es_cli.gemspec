# frozen_string_literal: true

require_relative "lib/es_cli/version"

Gem::Specification.new do |spec|
  spec.name = "es_cli"
  spec.version = EsCli::VERSION
  spec.authors = ["RyuRyu-0817"]
  spec.email = ["rusuzumi@outlook.jp"]

  spec.summary = "A CLI tool for managing and reviewing ES files."
  spec.description = "A command-line tool to create, edit, and review ES files, with AI integration for enhanced productivity."
  spec.homepage = "https://github.com/RyuRyu-0817/es_cli"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/RyuRyu-0817/es_cli"
  spec.metadata["changelog_uri"] = "https://github.com/RyuRyu-0817/es_cli/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency 'thor', '~> 1.3'
  spec.add_dependency 'ruby-openai', '~> 7.3'


  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
