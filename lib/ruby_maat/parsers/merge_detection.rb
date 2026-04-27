# frozen_string_literal: true

module RubyMaat
  module Parsers
    # Shared merge commit detection logic used by both GitParser and Git2Parser.
    # Extracted to avoid duplication and ensure patterns stay in sync.
    module MergeDetection
      MERGE_MESSAGE_PATTERNS = [
        /\AMerge pull request #\d+/i,
        /\AMerge branch '.*'/i,
        /\AMerge branch ".*"/i,
        /\AMerge remote-tracking branch/i,
        /\AMerged? (?:in|into) /i,
        /\AMerge .* into /i
      ].freeze

      private

      def merge_message?(message)
        MERGE_MESSAGE_PATTERNS.any? { |pattern| message.match?(pattern) }
      end
    end
  end
end
