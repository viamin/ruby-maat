# frozen_string_literal: true

module RubyMaat
  module Parsers
    # Team Foundation Server parser
    #
    # Input: tf hist /path/to/workspace /noprompt /format:detailed /recursive
    #
    # Sample format:
    # Changeset: 12345
    # User: DOMAIN\jdoe
    # Date: Friday, January 15, 2016 1:12:35 PM
    #
    # Comment:
    #   Fix bug in parser
    #
    # Items:
    #   edit $/Project/src/main.cs
    #   add $/Project/test/test.cs
    class TfsParser < BaseParser
      CHANGESET_PATTERN = /^Changeset:\s+(\d+)/
      USER_PATTERN = /^User:\s+(.+)/
      DATE_PATTERN = /^Date:\s+(.+)/
      ITEM_PATTERN = /^\s+(edit|add|delete)\s+(\S.+)/

      protected

      def parse_content(content)
        entries = []
        current_commit = nil
        in_items_section = false

        content.each_line do |line|
          line = line.chomp

          if (changeset_match = line.match(CHANGESET_PATTERN))
            # New changeset
            current_commit = {revision: changeset_match[1]}
            in_items_section = false
          elsif current_commit && (user_match = line.match(USER_PATTERN))
            # User line
            user = user_match[1].strip
            # Remove domain prefix if present (DOMAIN\user -> user)
            user = user.split("\\").last if user.include?("\\")
            current_commit[:author] = user
          elsif current_commit && (date_match = line.match(DATE_PATTERN))
            # Date line
            begin
              current_commit[:date] = parse_tfs_date(date_match[1])
            rescue ArgumentError
              # Skip this changeset if we can't parse the date
              current_commit = nil
              next
            end
          elsif line.strip == "Items:"
            # Start of items section
            in_items_section = true
          elsif current_commit && in_items_section && (item_match = line.match(ITEM_PATTERN))
            # Item change line
            action = item_match[1]
            file = item_match[2].strip

            # Skip deleted files and invalid paths
            next if action == "delete"
            next if file.empty? || file == "$/null"

            # Ensure we have all required fields
            next unless current_commit[:author] && current_commit[:date]

            entries << ChangeRecord.new(
              entity: file,
              author: current_commit[:author],
              date: current_commit[:date],
              revision: current_commit[:revision]
            )
          elsif line.strip.empty?
            # Empty line might separate sections
            in_items_section = false if in_items_section
          end
        end

        entries
      end

      private

      def parse_tfs_date(date_str)
        # TFS date format: "Friday, January 15, 2016 1:12:35 PM"
        # Note: The parser expects en-US locale format
        begin
          DateTime.strptime(date_str.strip, "%A, %B %d, %Y %I:%M:%S %p").to_date
        rescue Date::Error
          # Try alternative format without day of week
          DateTime.strptime(date_str.strip, "%B %d, %Y %I:%M:%S %p").to_date
        end
      rescue Date::Error => e
        raise ArgumentError,
          "Invalid TFS date format: #{date_str}. Expected en-US locale format like " \
          "'Friday, January 15, 2016 1:12:35 PM' (#{e.message})"
      end
    end
  end
end
