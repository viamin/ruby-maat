# frozen_string_literal: true

require "date"
require_relative "base_generator"

module RubyMaat
  module Generators
    class SvnGenerator < BaseGenerator
      PRESETS = {
        "standard" => {
          description: "Standard SVN XML log format",
          options: {
            verbose: true,
            xml: true
          }
        },
        "recent-activity" => {
          description: "Last 3 months of activity",
          options: {
            verbose: true,
            xml: true,
            since: (Date.today - 90).strftime("%Y%m%d")
          }
        },
        "last-year" => {
          description: "Last 12 months of activity",
          options: {
            verbose: true,
            xml: true,
            since: (Date.today - 365).strftime("%Y%m%d")
          }
        },
        "date-range" => {
          description: "Custom date range",
          options: {
            verbose: true,
            xml: true
          }
        },
        "revision-range" => {
          description: "Specific revision range",
          options: {
            verbose: true,
            xml: true
          }
        }
      }.freeze

      def available_presets
        PRESETS
      end

      protected

      def validate_repository!
        super

        svn_dir = File.join(@repository_path, ".svn")
        unless Dir.exist?(svn_dir)
          # Check if we're in an SVN working copy by running svn info
          begin
            `cd "#{@repository_path}" && svn info 2>/dev/null`
            if $?.exitstatus != 0
              raise ArgumentError, "Not an SVN working copy: #{@repository_path}"
            end
          rescue
            raise ArgumentError, "SVN not available or not an SVN working copy: #{@repository_path}"
          end
        end
      end

      def build_command(options)
        parts = ["svn", "log"]

        # Core options
        parts << "-v" if options[:verbose]
        parts << "--xml" if options[:xml]

        # Revision range (with validation and escaping)
        if options[:revision_start] && options[:revision_end]
          parts << "-r"
          parts << "#{validate_revision(options[:revision_start])}:#{validate_revision(options[:revision_end])}"
        elsif options[:revision_start]
          parts << "-r"
          parts << "#{validate_revision(options[:revision_start])}:HEAD"
        elsif options[:since] || options[:until]
          # Date-based revision range
          revision_range = build_date_revision_range(options)
          if revision_range
            parts << "-r"
            parts << revision_range
          end
        end

        # Limit
        parts << "-l"
        parts << options[:limit].to_s if options[:limit]

        # URL (if specified, otherwise use current directory) (with shell escaping)
        parts << shell_escape(options[:url]) if options[:url]

        parts.join(" ")
      end

      def gather_vcs_specific_options(options)
        super

        puts "\nSVN-specific options:"

        # Verbose output
        options[:verbose] = ask_yes_no("Include file paths? (verbose mode)",
          options.fetch(:verbose, true))

        # XML format
        options[:xml] = ask_yes_no("Use XML output format? (recommended)",
          options.fetch(:xml, true))

        # Revision range vs date range
        puts "\nRange selection:"
        puts "  1. Date range"
        puts "  2. Revision range"
        puts "  3. No range (full history)"

        range_choice = ask_integer("Choose range type", 1, 3)

        case range_choice
        when 1
          # Date range already handled by base class
        when 2
          rev_start = ask_string("Start revision (empty for beginning)")
          options[:revision_start] = rev_start unless rev_start.empty?

          rev_end = ask_string("End revision (empty for HEAD)")
          options[:revision_end] = rev_end unless rev_end.empty?

          # Clear date options if revision range is specified
          options.delete(:since)
          options.delete(:until)
        when 3
          # Clear all range options
          options.delete(:since)
          options.delete(:until)
          options.delete(:revision_start)
          options.delete(:revision_end)
        end

        # Limit
        limit = ask_string("Limit number of entries (empty for no limit)")
        options[:limit] = limit.to_i unless limit.empty?

        # URL
        url = ask_string("SVN URL (empty to use current working copy)")
        options[:url] = url unless url.empty?

        options
      end

      def supports_date_filtering?
        true
      end

      private

      def build_date_revision_range(options)
        if options[:since] && options[:until]
          "{#{validate_date(options[:since])}}:{#{validate_date(options[:until])}}"
        elsif options[:since]
          "{#{validate_date(options[:since])}}:HEAD"
        elsif options[:until]
          "1:{#{validate_date(options[:until])}}"
        end
      end

      def format_date_for_svn(date_str)
        # Convert YYYY-MM-DD to YYYYMMDD for SVN
        Date.parse(date_str).strftime("%Y%m%d")
      rescue Date::Error
        date_str
      end

      # Security methods to prevent command injection
      def shell_escape(value)
        return value unless value.is_a?(String)
        require "shellwords"
        Shellwords.escape(value)
      end

      def validate_revision(revision)
        # Only allow alphanumeric characters, dots, and basic revision keywords
        return revision if revision.to_s.match?(/\A[a-zA-Z0-9._-]+\z/)
        raise ArgumentError, "Invalid revision format: #{revision}"
      end

      def validate_date(date)
        # Validate date format and prevent injection
        return date if date.to_s.match?(/\A\d{4}-?\d{2}-?\d{2}\z/)
        raise ArgumentError, "Invalid date format: #{date}"
      end
    end
  end
end
