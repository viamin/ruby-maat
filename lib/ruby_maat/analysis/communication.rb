# frozen_string_literal: true

module RubyMaat
  module Analysis
    # Communication analysis - identifies developer collaboration patterns
    # Based on Conway's Law: organizations design systems that mirror their communication structure
    class Communication < BaseAnalysis
      def analyze(dataset, options = {})
        min_revs = options[:min_revs] || 5
        min_shared_revs = options[:min_shared_revs] || 5

        # Group entities by author to find their work domains
        author_entities = {}

        dataset.to_df.each_row do |row|
          author = row[:author]
          entity = row[:entity]

          author_entities[author] ||= Set.new
          author_entities[author] << entity
        end

        # Find pairs of authors who work on shared entities
        results = []
        author_pairs = author_entities.keys.combination(2)

        author_pairs.each do |author1, author2|
          shared_entities = author_entities[author1] & author_entities[author2]
          next if shared_entities.size < min_shared_revs

          author1_entities = author_entities[author1].size
          author2_entities = author_entities[author2].size

          # Communication strength based on shared work
          avg_entities = average(author1_entities, author2_entities)
          next if avg_entities < min_revs

          communication_strength = percentage(shared_entities.size, avg_entities)

          results << {
            author: author1,
            peer: author2,
            shared: shared_entities.size,
            average: avg_entities.ceil,
            strength: communication_strength
          }
        end

        # Sort by communication strength descending
        results.sort_by! { |r| -r[:strength] }

        to_csv_data(results, %i[author peer shared average strength])
      end
    end
  end
end
