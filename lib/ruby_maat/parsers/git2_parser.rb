# frozen_string_literal: true

require "date"
module RubyMaat
  module Parsers
    # Git2 parser - preferred Git parser (more tolerant and faster)
    #
    # Supports two formats:
    #
    # Standard format (without parent info):
    #   git log --all --numstat --date=short --pretty=format:'--%h--%ad--%aN--%s' --no-renames
    #
    # Enhanced format (with parent hashes for merge detection):
    #   git log --all --numstat --date=short --pretty=format:'--%h--%ad--%aN--PARENTS:%p%x09%s' --no-renames
    #   Note: "PARENTS:" sentinel + %x09 (literal tab) make the format unambiguous vs standard format
    #   (without the sentinel, standard subjects with hex-like starts and tabs could be misparsed).
    #
    # Sample standard format:
    # --586b4eb--2015-06-15--Adam Tornhill--Add new feature
    # 35      0       src/code_maat/mining/vcs.clj
    #
    # Sample enhanced format (merge commit has multiple parent hashes, tab before subject):
    # --abc123--2015-06-16--Jane Doe--PARENTS:def456 ghi789\tMerge pull request #42
    # 10      5       lib/example.rb
    class Git2Parser < BaseParser
      include MergeDetection

      # Enhanced format: hash--date--author--PARENTS:parents<TAB>message
      # Uses "PARENTS:" sentinel + tab to make enhanced format unambiguous vs standard format.
      # Without the sentinel, a standard-format subject starting with hex-like tokens and
      # containing a tab (e.g. "deadbeef\tsome text") could be misparsed as enhanced format.
      # Parents field uses * (zero or more) to handle root commits which have no parents.
      COMMIT_WITH_PARENTS = /^--([a-z0-9]+)--(\d{4}-\d{2}-\d{2})--(.+?)--PARENTS:([a-f0-9 ]*)\t([^\r\n]*)$/
      # Standard format: hash--date--author--message
      COMMIT_SEPARATOR = /^--([a-z0-9]+)--(\d{4}-\d{2}-\d{2})--(.+?)--([^\r\n]*)$/
      CHANGE_PATTERN = /^(-|\d+)[\t ]{1,10}(-|\d+)[\t ]{1,10}([^\r\n]*)$/

      protected

      def parse_content(content)
        records = []
        current_commit = nil

        content.each_line do |line|
          line.strip!
          next if line.empty?

          if (commit_match = line.match(COMMIT_WITH_PARENTS))
            parents = commit_match[4].strip.split
            message = commit_match[5].strip
            current_commit = {
              revision: commit_match[1],
              date: parse_date(commit_match[2]),
              author: commit_match[3].strip,
              message: message,
              # When parent hashes are available (enhanced format), parent count is
              # the authoritative merge signal. Message-based detection is only used
              # as a fallback in the standard format path (below).
              merge_commit: parents.size > 1
            }
          elsif (commit_match = line.match(COMMIT_SEPARATOR))
            message = commit_match[4].strip
            current_commit = {
              revision: commit_match[1],
              date: parse_date(commit_match[2]),
              author: commit_match[3].strip,
              message: message,
              merge_commit: merge_message?(message)
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
              merge_commit: current_commit[:merge_commit]
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
