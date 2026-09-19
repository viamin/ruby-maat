# frozen_string_literal: true

require "date"
module RubyMaat
  module Parsers
    # Git2 parser - preferred Git parser (more tolerant and faster)
    #
    # Input: git log --all --numstat --date=short --pretty=format:'--%h--%ad--%aN--%s' --no-renames --after=YYYY-MM-DD
    #
    # Sample format:
    # --586b4eb--2015-06-15--Adam Tornhill--Add new feature
    # 35      0       src/code_maat/mining/vcs.clj
    # 2       1       test/file.rb
    #
    # --abc123--2015-06-16--Jane Doe--Fix bug in parser
    # 10      5       lib/example.rb
    class Git2Parser < BaseParser
      # Format with parent hashes: --hash--parent1 parent2--date--author--message
      COMMIT_WITH_PARENTS = /^--([a-z0-9]+)--([a-z0-9 ]*)--(\d{4}-\d{2}-\d{2})--([^\r\n]+?)--([^\r\n]*)$/
      # Standard format: --hash--date--author--message
      COMMIT_SEPARATOR = /^--([a-z0-9]+)--(\d{4}-\d{2}-\d{2})--([^\r\n]+?)--([^\r\n]*)$/
      CHANGE_PATTERN = /^(-|\d+)[\t ]{1,10}(-|\d+)[\t ]{1,10}([^\r\n]*)$/

      protected

      def parse_content(content)
        records = []
        current_commit = nil

        content.each_line do |line|
          line.strip!
          next if line.empty?

          if (commit_match = line.match(COMMIT_WITH_PARENTS))
            parents_str = commit_match[2].strip
            current_commit = {
              revision: commit_match[1],
              parent_revisions: parents_str.empty? ? [] : parents_str.split,
              date: parse_date(commit_match[3]),
              author: commit_match[4].strip,
              message: commit_match[5].strip
            }
          elsif (commit_match = line.match(COMMIT_SEPARATOR))
            current_commit = {
              revision: commit_match[1],
              parent_revisions: nil,
              date: parse_date(commit_match[2]),
              author: commit_match[3].strip,
              message: commit_match[4].strip
            }
          elsif current_commit && (change_match = line.match(CHANGE_PATTERN))
            added = clean_numstat(change_match[1])
            deleted = clean_numstat(change_match[2])
            file = change_match[3].strip

            next if file.empty? || file == File::NULL
            next if added.nil? && deleted.nil?

            records << ChangeRecord.new(
              entity: file,
              author: current_commit[:author],
              date: current_commit[:date],
              revision: current_commit[:revision],
              message: current_commit[:message],
              loc_added: added,
              loc_deleted: deleted,
              parent_revisions: current_commit[:parent_revisions]
            )
          end
        end

        records
      end

      private

      def parse_date(date_str)
        Date.parse(date_str)
      rescue Date::Error
        nil
      end

      def clean_numstat(value)
        (value == "-") ? nil : value.to_i
      end
    end
  end
end
