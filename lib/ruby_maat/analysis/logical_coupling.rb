# frozen_string_literal: true

module RubyMaat
  module Analysis
    # Logical coupling analysis - finds modules that tend to change together
    # This identifies hidden dependencies between code modules
    class LogicalCoupling < BaseAnalysis
      def analyze(dataset, options = {})
        min_revs = options[:min_revs] || 1
        min_shared_revs = options[:min_shared_revs] || 1
        min_coupling = options[:min_coupling] || 1
        max_coupling = options[:max_coupling] || 100
        max_changeset_size = options[:max_changeset_size] || 30
        verbose_results = options[:verbose_results] || false

        # Get co-changing entities by revision
        co_changing_entities = get_co_changing_entities(dataset, max_changeset_size)

        # Calculate coupling frequencies
        coupling_frequencies = calculate_coupling_frequencies(co_changing_entities)

        # Calculate revision counts per entity
        entity_revisions = calculate_entity_revisions(dataset)

        # Generate coupling results
        results = []

        coupling_frequencies.each do |(entity1, entity2), shared_revs|
          entity1_revs = entity_revisions[entity1] || 0
          entity2_revs = entity_revisions[entity2] || 0

          avg_revs = average(entity1_revs, entity2_revs)
          coupling_degree = percentage(shared_revs, avg_revs)

          # Apply thresholds
          next unless avg_revs >= min_revs
          next unless shared_revs >= min_shared_revs
          next unless coupling_degree >= min_coupling
          next unless coupling_degree <= max_coupling

          result = {
            entity: entity1,
            coupled: entity2,
            degree: coupling_degree,
            "average-revs": avg_revs.ceil
          }

          if verbose_results
            result.merge!(
              "first-entity-revisions": entity1_revs,
              "second-entity-revisions": entity2_revs,
              "shared-revisions": shared_revs
            )
          end

          results << result
        end

        # Sort by coupling degree (descending), then by average revisions (descending)
        results.sort! do |a, b|
          comparison = b[:degree] <=> a[:degree]
          comparison.zero? ? b[:"average-revs"] <=> a[:"average-revs"] : comparison
        end

        columns = [:entity, :coupled, :degree, :"average-revs"]
        columns += [:"first-entity-revisions", :"second-entity-revisions", :"shared-revisions"] if verbose_results

        to_csv_data(results, columns)
      end

      private

      def get_co_changing_entities(dataset, max_changeset_size)
        # Group changes by revision to find entities that changed together
        by_revision = {}

        dataset.to_df.to_a.each do |row|
          revision = row["revision"]
          entity = row["entity"]

          by_revision[revision] ||= []
          by_revision[revision] << entity
        end

        # Convert to co-changing pairs, filtering by changeset size
        co_changing = []

        by_revision.each_value do |entities|
          # Skip large changesets to avoid noise
          next if entities.size > max_changeset_size

          # Get unique entities (remove duplicates)
          unique_entities = entities.uniq

          # Generate all combinations of 2 entities
          unique_entities.combination(2) do |entity1, entity2|
            # Sort to ensure consistent ordering
            pair = [entity1, entity2].sort
            co_changing << pair
          end
        end

        co_changing
      end

      def calculate_coupling_frequencies(co_changing_entities)
        # Count how many times each pair changed together
        frequencies = Hash.new(0)

        co_changing_entities.each do |pair|
          frequencies[pair] += 1
        end

        frequencies
      end

      def calculate_entity_revisions(dataset)
        # Count unique revisions per entity from the dataset
        entity_revisions = {}

        dataset.to_df.to_a.each do |row|
          entity = row["entity"]
          revision = row["revision"]

          entity_revisions[entity] ||= Set.new
          entity_revisions[entity] << revision
        end

        # Convert to counts
        entity_revisions.transform_values(&:size)
      end
    end
  end
end
