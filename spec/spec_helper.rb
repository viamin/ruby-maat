# frozen_string_literal: true

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

  # Allow more verbose output when running with --format documentation
  config.default_formatter = "doc" if config.files_to_run.one?

  # Run specs in random order to surface order dependencies.
  config.order = :random
  Kernel.srand config.seed
end
