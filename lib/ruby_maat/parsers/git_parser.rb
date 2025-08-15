# frozen_string_literal: true

module RubyMaat
  module Parsers
    # Legacy Git parser for backward compatibility
    #
    # Input: git log --pretty=format:'[%h] %aN %ad %s' --date=short --numstat --after=YYYY-MM-DD
    #
    # Sample format:
    # [586b4eb] Adam Tornhill 2015-06-15 Add new feature
    # 35      0       src/code_maat/mining/vcs.clj
    # 2       1       test/file.rb
    #
    # [abc123] Jane Doe 2015-06-16 Fix bug in parser
    # 10      5       lib/example.rb
    class GitParser < BaseParser
      COMMIT_PATTERN = /^\[([a-f0-9]+)\]\s+(.+?)\s+(\d{4}-\d{2}-\d{2})\s+(.*)$/
      CHANGE_PATTERN = /^(\d+|-)\s+(\d+|-)\s+(.+)$/

      protected

      def parse_content(content)
        entries = []
        current_commit = nil

        content.each_line do |line|
          line = line.chomp

          # Skip empty lines
          next if line.strip.empty?

          if (commit_match = line.match(COMMIT_PATTERN))
            # New commit header
            current_commit = {
              revision: commit_match[1],
              author: commit_match[2].strip,
              date: parse_date(commit_match[3]),
              message: commit_match[4].strip
            }
          elsif current_commit && (change_match = line.match(CHANGE_PATTERN))
            # File change line
            added = clean_numstat(change_match[1])
            deleted = clean_numstat(change_match[2])
            file = change_match[3].strip

            # Skip empty or invalid file names
            next if file.empty? || file == File::NULL

            entries << ChangeRecord.new(
              entity: file,
              author: current_commit[:author],
              date: current_commit[:date],
              revision: current_commit[:revision],
              message: current_commit[:message],
              loc_added: added,
              loc_deleted: deleted
            )
          end
          # Ignore unrecognized lines
        end

        entries
      end
    end
  end
end
