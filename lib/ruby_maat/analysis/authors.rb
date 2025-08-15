# frozen_string_literal: true

module RubyMaat
  module Analysis
    # Authors analysis - counts distinct authors per entity
    # Research shows that the number of authors of a module is related to quality problems
    class Authors < BaseAnalysis
      def analyze(dataset, options = {})
        min_revs = options[:min_revs] || 5

        # Group by entity and count distinct authors and revisions manually
        entity_stats = {}

        dataset.to_df.each_row do |row|
          entity = row["entity"]
          author = row["author"]
          revision = row["revision"]

          entity_stats[entity] ||= {authors: Set.new, revisions: Set.new}
          entity_stats[entity][:authors] << author
          entity_stats[entity][:revisions] << revision
        end

        # Build results and apply minimum revisions filter
        results = []
        entity_stats.each do |entity, stats|
          n_revs = stats[:revisions].size
          next if n_revs < min_revs

          results << {
            entity: entity,
            "n-authors": stats[:authors].size,
            "n-revs": n_revs
          }
        end

        # Sort by number of authors (descending), then by revisions (descending)
        results.sort! do |a, b|
          comparison = b[:"n-authors"] <=> a[:"n-authors"]
          comparison.zero? ? b[:"n-revs"] <=> a[:"n-revs"] : comparison
        end

        to_csv_data(results, %i[entity n-authors n-revs])
      end
    end
  end
end
