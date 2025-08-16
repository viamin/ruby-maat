# frozen_string_literal: true

require "date"
require_relative "base_generator"

module RubyMaat
  module Generators
    class GitGenerator < BaseGenerator
      PRESETS = {
        "git2-format" => {
          description: "Standard format for git2 parser (recommended)",
          options: {
            format: "git2",
            no_renames: true,
            all_branches: true
          }
        },
        "git-legacy" => {
          description: "Legacy format for git parser",
          options: {
            format: "legacy",
            no_renames: true,
            all_branches: false
          }
        },
        "recent-activity" => {
          description: "Last 3 months of activity",
          options: {
            format: "git2",
            since: (Date.today - 90).strftime("%Y-%m-%d"),
            no_renames: true,
            all_branches: true
          }
        },
        "last-year" => {
          description: "Last 12 months of activity",
          options: {
            format: "git2",
            since: (Date.today - 365).strftime("%Y-%m-%d"),
            no_renames: true,
            all_branches: true
          }
        },
        "full-history" => {
          description: "Complete repository history (may be large)",
          options: {
            format: "git2",
            no_renames: true,
            all_branches: true
          }
        }
      }.freeze

      def available_presets
        PRESETS
      end

      protected

      def validate_repository!
        super

        git_dir = File.join(@repository_path, ".git")
        unless Dir.exist?(git_dir) || File.exist?(git_dir)
          raise ArgumentError, "Not a Git repository: #{@repository_path}"
        end
      end

      def build_command(options)
        format = options[:format] || "git2"

        case format
        when "git2"
          build_git2_command(options)
        when "legacy"
          build_legacy_command(options)
        else
          raise ArgumentError, "Unknown Git format: #{format}"
        end
      end

      def gather_vcs_specific_options(options)
        super

        puts "\nGit-specific options:"

        # Format selection
        puts "Output formats:"
        puts "  1. git2 (recommended, faster parsing)"
        puts "  2. legacy (backward compatibility)"

        format_choice = ask_integer("Choose format", 1, 2)
        options[:format] = (format_choice == 1) ? "git2" : "legacy"

        # Branch selection
        options[:all_branches] = ask_yes_no("Include all branches?", options[:all_branches])

        # Rename detection
        options[:no_renames] = ask_yes_no("Disable rename detection? (recommended for performance)",
          options.fetch(:no_renames, true))

        # Author filtering
        author = ask_string("Filter by author (empty for all)")
        options[:author] = author unless author.empty?

        # Path filtering
        path = ask_string("Filter by path pattern (empty for all files)")
        options[:path] = path unless path.empty?

        options
      end

      private

      def build_git2_command(options)
        parts = ["git log"]

        # Core git2 format options
        parts << "--all" if options[:all_branches]
        parts << "--numstat"
        parts << "--date=short"
        parts << "--pretty=format:'--%h--%ad--%aN'"
        parts << "--no-renames" if options[:no_renames]

        # Date filtering
        parts << "--after=#{options[:since]}" if options[:since]
        parts << "--before=#{options[:until]}" if options[:until]

        # Author filtering
        parts << "--author='#{options[:author]}'" if options[:author]

        # Add path at the end if specified
        parts << "-- #{options[:path]}" if options[:path]

        parts.join(" ")
      end

      def build_legacy_command(options)
        parts = ["git log"]

        # Core legacy format options
        parts << "--all" if options[:all_branches]
        parts << "--pretty=format:'[%h] %aN %ad %s'"
        parts << "--date=short"
        parts << "--numstat"
        parts << "--no-renames" if options[:no_renames]

        # Date filtering
        parts << "--after=#{options[:since]}" if options[:since]
        parts << "--before=#{options[:until]}" if options[:until]

        # Author filtering
        parts << "--author='#{options[:author]}'" if options[:author]

        # Add path at the end if specified
        parts << "-- #{options[:path]}" if options[:path]

        parts.join(" ")
      end
    end
  end
end
