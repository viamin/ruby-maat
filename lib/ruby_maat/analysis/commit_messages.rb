# frozen_string_literal: true

module RubyMaat
  module Analysis
    # Commit messages analysis - word frequency analysis of commit messages
    class CommitMessages < BaseAnalysis
      def analyze(dataset, options = {})
        expression = options[:expression_to_match]

        # Extract commit messages
        messages = dataset.to_df[:message].compact

        # Filter by regex if provided
        if expression
          regex = Regexp.new(expression, Regexp::IGNORECASE)
          messages = messages.grep(regex)
        end

        # Tokenize and count words
        word_frequencies = Hash.new(0)

        messages.each do |message|
          # Simple tokenization: split on whitespace and punctuation, convert to lowercase
          words = message.downcase.split(/[^a-zA-Z0-9]+/).reject(&:empty?)

          # Filter out common stop words and very short words
          words = words.reject { |word| word.length < 3 || stop_words.include?(word) }

          words.each { |word| word_frequencies[word] += 1 }
        end

        # Convert to results format
        results = word_frequencies.map do |word, frequency|
          {
            word: word,
            frequency: frequency
          }
        end

        # Sort by frequency descending
        results.sort_by! { |r| -r[:frequency] }

        to_csv_data(results, %i[word frequency])
      end

      private

      def stop_words
        %w[
          the and or but for with from that this will was are has have had been
          can could would should may might must shall
          not don't doesn't didn't won't wasn't weren't isn't aren't hasn't haven't
          add fix update remove delete change modify refactor implement
        ].to_set
      end
    end
  end
end
