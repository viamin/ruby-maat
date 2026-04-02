# frozen_string_literal: true

require_relative "ruby_maat/version"
require_relative "ruby_maat/change_record"
require_relative "ruby_maat/dataset"

# Set is part of Ruby core since 3.2, so no explicit require is needed.
# Earlier Ruby versions pulled it in transitively via gems, but this project
# requires Ruby 3.3+ where Set is always available without require.

# Core parsers
require_relative "ruby_maat/parsers/base_parser"
require_relative "ruby_maat/parsers/merge_detection"
require_relative "ruby_maat/parsers/git_parser"
require_relative "ruby_maat/parsers/git2_parser"
require_relative "ruby_maat/parsers/svn_parser"
require_relative "ruby_maat/parsers/mercurial_parser"
require_relative "ruby_maat/parsers/perforce_parser"
require_relative "ruby_maat/parsers/tfs_parser"

# Data processors
require_relative "ruby_maat/groupers/layer_grouper"
require_relative "ruby_maat/groupers/time_grouper"
require_relative "ruby_maat/groupers/team_mapper"

# Analysis modules (load before app.rb since app references them)
require_relative "ruby_maat/analysis/base_analysis"
require_relative "ruby_maat/analysis/authors"
require_relative "ruby_maat/analysis/entities"
require_relative "ruby_maat/analysis/logical_coupling"
require_relative "ruby_maat/analysis/merge_coupling"
require_relative "ruby_maat/analysis/churn"
require_relative "ruby_maat/analysis/effort"
require_relative "ruby_maat/analysis/communication"
require_relative "ruby_maat/analysis/code_age"
require_relative "ruby_maat/analysis/summary"
require_relative "ruby_maat/analysis/commit_messages"
require_relative "ruby_maat/analysis/sum_of_coupling"
require_relative "ruby_maat/analysis/identity"

# Output
require_relative "ruby_maat/output/csv_output"

# Main app and CLI (load after dependencies)
require_relative "ruby_maat/app"
require_relative "ruby_maat/cli"

module RubyMaat
  class Error < StandardError; end
end
