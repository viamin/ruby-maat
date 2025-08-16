# frozen_string_literal: true

module RubyMaat
  module Parsers
    # Mercurial parser
    #
    # Input: hg log --template "rev: {rev} author: {author} date: {date|shortdate} files:\n{files %'{file}\n'}\n" --date ">YYYY-MM-DD"
    #
    # Sample format:
    # rev: 123 author: John Doe date: 2015-06-15 files:
    # src/main.py
    # test/test_main.py
    #
    # rev: 124 author: Jane Smith date: 2015-06-16 files:
    # lib/helper.py
    class MercurialParser < BaseParser
      ENTRY_PATTERN = /^rev:\s+(\d+)\s+author:\s+([^0-9]+)\s+date:\s+(\d{4}-\d{2}-\d{2})\s+files:$/

      protected

      def parse_content(content)
        entries = []
        current_commit = nil
        in_files_section = false

        content.each_line do |line|
          line = line.chomp

          if line.strip.empty?
            # Empty line marks end of current commit
            current_commit = nil
            in_files_section = false
            next
          end

          if (commit_match = line.match(ENTRY_PATTERN))
            # New commit header
            current_commit = {
              revision: commit_match[1],
              author: commit_match[2].strip,
              date: parse_date(commit_match[3])
            }
            in_files_section = true
          elsif current_commit && in_files_section && !line.strip.empty?
            # File line
            file = line.strip

            # Skip invalid file names
            next if file.empty? || file == File::NULL

            entries << ChangeRecord.new(
              entity: file,
              author: current_commit[:author],
              date: current_commit[:date],
              revision: current_commit[:revision]
            )
          end
        end

        entries
      end
    end
  end
end
