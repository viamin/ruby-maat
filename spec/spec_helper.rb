# frozen_string_literal: true

# Code coverage tracking
require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/test/"
  add_filter "/vendor/"

  add_group "Library", "lib"
  add_group "Analyses", "lib/ruby_maat/analysis"
  add_group "Parsers", "lib/ruby_maat/parsers"
  add_group "Output", "lib/ruby_maat/output"

  minimum_coverage 45
end

require_relative "../lib/ruby_maat"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Uncomment if using Rails (not applicable for this gem)
  # config.filter_rails_from_backtrace!

  # Show progress during test runs
  config.default_formatter = "progress" if config.files_to_run.one?

  # Run specs in random order to surface order dependencies.
  config.order = :random
  Kernel.srand config.seed
end
