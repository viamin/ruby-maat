# frozen_string_literal: true

module RubyMaat
  module Parsers
    # Base class for all VCS parsers
    class BaseParser
      def initialize(log_file, options = {})
        @log_file = log_file
        @options = options
        @encoding = options[:input_encoding] || "UTF-8"
      end

      def parse
        validate_file_exists!
        content = read_log_file
        parse_content(content)
      rescue => e
        handle_parse_error(e)
      end

      protected

      def read_log_file
        File.read(@log_file, encoding: @encoding)
      rescue Encoding::InvalidByteSequenceError
        raise ArgumentError, "Invalid encoding for log file. Try specifying --input-encoding"
      end

      def validate_file_exists!
        return if File.exist?(@log_file)

        raise ArgumentError, "Log file not found: #{@log_file}"
      end

      def parse_content(content)
        raise NotImplementedError, "Subclasses must implement parse_content"
      end

      def handle_parse_error(error)
        case error
        when ArgumentError
          raise error
        else
          vcs_name = self.class.name.split("::").last.gsub("Parser", "")
          raise ArgumentError, "#{vcs_name}: Failed to parse the given file - is it a valid logfile? (#{error.message})"
        end
      end

      def parse_date(date_str)
        Date.parse(date_str)
      rescue Date::Error
        raise ArgumentError, "Invalid date format: #{date_str}"
      end

      # Helper to clean up binary file indicators and handle edge cases
      def clean_numstat(value)
        return nil if value.nil? || value.empty? || value == "-"

        value.to_i
      end
    end
  end
end
