# frozen_string_literal: true

module RubyMaat
  module Analysis
    # Merge-based coupling analysis - finds modules that change together within merge commits
    #
    # Traditional coupling analysis treats each commit independently. This analysis
    # groups all changes that belong to the same merge commit (i.e., PR) and treats
    # them as a single logical unit. This provides better coupling signals because
    # files that change together in a PR are more likely to be truly coupled than
    # files that just happened to change in nearby commits.
    #
    # Merge commits are identified by:
    # 1. Having multiple parent commits (detected via enhanced git log format with %p)
    # 2. Commit message patterns (e.g., "Merge pull request #42", "Merge branch 'feature'")
    #
    # Grouping heuristic (log-order segmentation):
    # - Each merge commit starts a new group
    # - Non-merge commits that follow a merge are added to that merge's group
    # - Non-merge commits that appear before any merge form standalone groups
    class MergeCoupling < BaseAnalysis
      def analyze(dataset, options = {})
        min_revs = options[:min_revs] || 1
        min_shared_revs = options[:min_shared_revs] || 1
        min_coupling = options[:min_coupling] || 1
        max_coupling = options[:max_coupling] || 100
        max_changeset_size = options[:max_changeset_size] || 30
        verbose_results = options[:verbose_results] || false

        # Group entities by merge boundaries instead of individual commits
        merge_groups = build_merge_groups(dataset)

        # Get co-changing entities by merge group
        co_changing_entities = get_co_changing_entities(merge_groups, max_changeset_size)

        # Calculate coupling frequencies
        coupling_frequencies = calculate_coupling_frequencies(co_changing_entities)

        # Calculate revision counts per entity (using merge groups as revisions)
        entity_revisions = calculate_entity_revisions(merge_groups)

        # Generate coupling results
        results = build_results(coupling_frequencies, entity_revisions,
          min_revs, min_shared_revs, min_coupling, max_coupling, verbose_results)

        # Sort by coupling degree descending, then by average revisions descending
        results.sort! do |a, b|
          comparison = b[:degree] <=> a[:degree]
          comparison.zero? ? b[:"average-revs"] <=> a[:"average-revs"] : comparison
        end

        columns = [:entity, :coupled, :degree, :"average-revs"]
        columns += [:"first-entity-revisions", :"second-entity-revisions", :"shared-revisions"] if verbose_results

        to_csv_data(results, columns)
      end

      private

      # Build merge groups using log-order segmentation.
      # Scans revisions in dataset order and segments them into groups:
      # - A merge commit starts a new group keyed by its revision
      # - Subsequent non-merge commits are appended to the most recent merge group
      # - Non-merge commits appearing before the first merge each form a standalone group
      # This approximates PR boundaries when the log is in reverse-chronological order.
      def build_merge_groups(dataset)
        rows = dataset.to_df.to_a

        # Collect unique revisions in order, preserving their merge status and entities
        revision_info = {}
        revision_order = []

        rows.each do |row|
          rev = row["revision"]
          merge_flag = merge_value?(row["merge_commit"])

          if revision_info.key?(rev)
            # Promote a revision to merge if any of its rows indicate a merge
            revision_info[rev][:merge] ||= merge_flag
          else
            revision_info[rev] = {
              merge: merge_flag,
              entities: Set.new
            }
            revision_order << rev
          end
          revision_info[rev][:entities] << row["entity"]
        end

        # Group revisions by merge boundaries
        groups = {}
        current_merge_id = nil

        revision_order.each do |rev|
          info = revision_info[rev]

          if info[:merge]
            # This is a merge commit - it defines a group
            current_merge_id = rev
            groups[current_merge_id] ||= Set.new
            groups[current_merge_id].merge(info[:entities])
          elsif current_merge_id
            # Non-merge commit after a merge - add to the current merge group
            groups[current_merge_id].merge(info[:entities])
          else
            # Non-merge commit before any merge - standalone group
            groups[rev] = info[:entities].dup
          end
        end

        groups
      end

      def get_co_changing_entities(merge_groups, max_changeset_size)
        co_changing = []

        merge_groups.each_value do |entities|
          entity_list = entities.to_a
          next if entity_list.size > max_changeset_size

          entity_list.combination(2) do |entity1, entity2|
            pair = [entity1, entity2].sort
            co_changing << pair
          end
        end

        co_changing
      end

      def calculate_coupling_frequencies(co_changing_entities)
        frequencies = Hash.new(0)

        co_changing_entities.each do |pair|
          frequencies[pair] += 1
        end

        frequencies
      end

      def calculate_entity_revisions(merge_groups)
        entity_revisions = Hash.new(0)

        merge_groups.each_value do |entities|
          entities.each do |entity|
            entity_revisions[entity] += 1
          end
        end

        entity_revisions
      end

      # Rover DataFrame converts booleans to integers (1/0).
      # This normalizes the value back to a boolean.
      def merge_value?(value)
        value == true || value == 1
      end

      def build_results(coupling_frequencies, entity_revisions,
        min_revs, min_shared_revs, min_coupling, max_coupling, verbose_results)
        results = []

        coupling_frequencies.each do |(entity1, entity2), shared_revs|
          entity1_revs = entity_revisions[entity1] || 0
          entity2_revs = entity_revisions[entity2] || 0

          avg_revs = average(entity1_revs, entity2_revs)
          coupling_degree = percentage(shared_revs, avg_revs)

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

        results
      end
    end
  end
end
