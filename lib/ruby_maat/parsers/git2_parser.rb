# frozen_string_literal: true

module RubyMaat
  module Parsers
    # Git2 parser - preferred Git parser (more tolerant and faster)
    #
    # Input: git log --all --numstat --date=short --pretty=format:'--%h--%ad--%aN' --no-renames --after=YYYY-MM-DD
    #
    # Sample format:
    # --586b4eb--2015-06-15--Adam Tornhill
    # 35      0       src/code_maat/mining/vcs.clj
    # 2       1       test/file.rb
    #
    # --abc123--2015-06-16--Jane Doe
    # 10      5       lib/example.rb
    class Git2Parser < BaseParser
      COMMIT_SEPARATOR = /^--([a-f0-9]+)--(\d{4}-\d{2}-\d{2})--(.+)$/
      CHANGE_PATTERN = /^(\d+|-)\s+(\d+|-)\s+(.+)$/

      protected

      def parse_content(content)
        entries = []
        current_commit = nil

        content.each_line do |line|
          line = line.chomp

          # Skip empty lines
          next if line.strip.empty?

          if (commit_match = line.match(COMMIT_SEPARATOR))
            # New commit header
            current_commit = {
              revision: commit_match[1],
              date: parse_date(commit_match[2]),
              author: commit_match[3].strip
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
              loc_added: added,
              loc_deleted: deleted
            )
          end
          # Ignore unrecognized lines (could be merge info, etc.)
        end

        entries
      end
    end
  end
end
