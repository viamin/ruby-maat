# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

# Override the release task to skip tag creation since release-please handles it
Rake::Task["release"].clear
desc "Build and push gem to RubyGems (skips tag creation - handled by release-please)"
task :release do
  Rake::Task["build"].invoke
  Rake::Task["rubygem:push"].invoke
end

task default: %i[spec rubocop]
