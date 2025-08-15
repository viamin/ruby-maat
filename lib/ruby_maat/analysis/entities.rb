# frozen_string_literal: true

module RubyMaat
  module Analysis
    # Entities analysis - counts revisions per entity
    class Entities < BaseAnalysis
      def analyze(dataset, options = {})
        min_revs = options[:min_revs] || 5

        # Group by entity and count revisions manually
        entity_stats = {}

        dataset.to_df.each_row do |row|
          entity = row["entity"]
          revision = row["revision"]

          entity_stats[entity] ||= Set.new
          entity_stats[entity] << revision
        end

        # Build results and apply minimum revisions filter
        results = []
        entity_stats.each do |entity, revisions|
          n_revs = revisions.size
          next if n_revs < min_revs

          results << {
            entity: entity,
            "n-revs": n_revs
          }
        end

        # Sort by number of revisions (descending)
        results.sort! { |a, b| b[:"n-revs"] <=> a[:"n-revs"] }

        to_csv_data(results, %i[entity n-revs])
      end
    end
  end
end
