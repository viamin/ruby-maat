# frozen_string_literal: true

require "rexml/document"

module RubyMaat
  module Parsers
    # SVN parser for XML log files
    #
    # Input: svn log -v --xml > logfile.log -r {YYYYmmDD}:HEAD
    #
    # Sample XML format:
    # <log>
    #   <logentry revision="12345">
    #     <author>jdoe</author>
    #     <date>2015-06-15T10:30:45.123456Z</date>
    #     <paths>
    #       <path action="M">/trunk/src/file.java</path>
    #       <path action="A">/trunk/test/test.java</path>
    #     </paths>
    #     <msg>Fix bug in parser</msg>
    #   </logentry>
    # </log>
    class SvnParser < BaseParser
      protected

      def parse_content(content)
        entries = []

        begin
          doc = REXML::Document.new(content)

          doc.elements.each("log/logentry") do |logentry|
            revision = logentry.attributes["revision"]
            author = logentry.elements["author"]&.text || "unknown"
            date_text = logentry.elements["date"]&.text
            message = logentry.elements["msg"]&.text || ""

            next unless date_text && revision

            date = parse_svn_date(date_text)

            # Extract all path changes
            logentry.elements.each("paths/path") do |path_element|
              entity = path_element.text&.strip
              path_element.attributes["action"]

              next if entity.nil? || entity.empty?

              entries << ChangeRecord.new(
                entity: entity,
                author: author,
                date: date,
                revision: revision,
                message: message
              )
            end
          end
        rescue REXML::ParseException => e
          raise ArgumentError, "Invalid XML format in SVN log file: #{e.message}"
        end

        entries
      end

      private

      def parse_svn_date(date_str)
        # SVN date format: 2015-06-15T10:30:45.123456Z
        # Convert to Date object
        DateTime.parse(date_str).to_date
      rescue => e
        raise ArgumentError, "Invalid SVN date format: #{date_str} (#{e.message})"
      end
    end
  end
end
