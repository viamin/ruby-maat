# frozen_string_literal: true

module RubyMaat
  module Parsers
    # Perforce parser
    #
    # Input: p4 changes -s submitted -m 5000 //depot/project/... | cut -d ' ' -f 2 | xargs -I commitid -n1 sh -c 'p4 describe -s commitid | grep -v "^\s*$" && echo ""'
    #
    # Sample format:
    # Change 12345 by jdoe@workspace on 2015/06/15 10:30:45
    #
    #         Fix bug in parser
    #
    # Affected files ...
    #
    # ... //depot/project/src/main.java#2 edit
    # ... //depot/project/test/test.java#1 add
    class PerforceParser < BaseParser
      CHANGE_PATTERN = %r{^Change\s+(\d+)\s+by\s+([^@]+)@\S+\s+on\s+(\d{4}/\d{2}/\d{2})}
      FILE_PATTERN = /^\.\.\.\s+([^#]+)#\d+\s+(\w+)/

      protected

      def parse_content(content)
        entries = []
        current_commit = nil
        in_files_section = false

        content.each_line do |line|
          line = line.chomp

          if (change_match = line.match(CHANGE_PATTERN))
            # New changelist header
            current_commit = {
              revision: change_match[1],
              author: change_match[2].strip,
              date: parse_perforce_date(change_match[3])
            }
            in_files_section = false
          elsif line.include?("Affected files")
            # Start of files section
            in_files_section = true
          elsif current_commit && in_files_section && (file_match = line.match(FILE_PATTERN))
            # File change line
            file = file_match[1].strip
            action = file_match[2]

            # Skip deleted files for most analyses (they don't contribute to current state)
            next if action == "delete"
            next if file.empty?

            entries << ChangeRecord.new(
              entity: file,
              author: current_commit[:author],
              date: current_commit[:date],
              revision: current_commit[:revision]
            )
          elsif line.strip.empty? && current_commit
            # Empty line might end current changelist
            # But we keep current_commit until we see a new one
          end
        end

        entries
      end

      private

      def parse_perforce_date(date_str)
        # Perforce date format: 2015/06/15
        Date.strptime(date_str, "%Y/%m/%d")
      rescue Date::Error => e
        raise ArgumentError, "Invalid Perforce date format: #{date_str} (#{e.message})"
      end
    end
  end
end
