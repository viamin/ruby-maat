# frozen_string_literal: true

module RubyMaat
  module Analysis
    module Churn
      # Absolute churn analysis - code churn trends over time
      class Absolute < BaseAnalysis
        def analyze(dataset, _options = {})
          # Group by date and sum churn metrics, count commits
          results = {}

          dataset.to_df.each_row do |row|
            date = row["date"]
            added = row["loc_added"] || 0
            deleted = row["loc_deleted"] || 0
            revision = row["revision"]

            results[date] ||= {date: date, added: 0, deleted: 0, revisions: Set.new}
            results[date][:added] += added
            results[date][:deleted] += deleted
            results[date][:revisions] << revision
          end

          # Convert to final format
          final_results = results.values.map do |result|
            {
              date: result[:date],
              added: result[:added],
              deleted: result[:deleted],
              commits: result[:revisions].size
            }
          end

          # Sort by date
          final_results.sort_by! { |r| r[:date] }

          to_csv_data(final_results, %i[date added deleted commits])
        end
      end

      # Author churn analysis - churn metrics per author
      class ByAuthor < BaseAnalysis
        def analyze(dataset, _options = {})
          # Group by author and sum churn metrics, count commits
          results = {}

          dataset.to_df.each_row do |row|
            author = row["author"]
            added = row["loc_added"] || 0
            deleted = row["loc_deleted"] || 0
            revision = row["revision"]

            results[author] ||= {author: author, added: 0, deleted: 0, revisions: Set.new}
            results[author][:added] += added
            results[author][:deleted] += deleted
            results[author][:revisions] << revision
          end

          # Convert to final format
          final_results = results.values.map do |result|
            {
              author: result[:author],
              added: result[:added],
              deleted: result[:deleted],
              commits: result[:revisions].size
            }
          end

          # Sort by total churn (added + deleted) descending, then by added lines descending, then by author
          final_results.sort! do |a, b|
            total_churn_b = b[:added] + b[:deleted]
            total_churn_a = a[:added] + a[:deleted]
            churn_comparison = total_churn_b <=> total_churn_a

            if churn_comparison.zero?
              added_comparison = b[:added] <=> a[:added]
              added_comparison.zero? ? a[:author] <=> b[:author] : added_comparison
            else
              churn_comparison
            end
          end

          to_csv_data(final_results, %i[author added deleted commits])
        end
      end

      # Entity churn analysis - churn metrics per entity
      class ByEntity < BaseAnalysis
        def analyze(dataset, options = {})
          min_revs = options[:min_revs] || 5

          # Group by entity and sum churn metrics
          results = {}

          dataset.to_df.each_row do |row|
            entity = row["entity"]
            added = row["loc_added"] || 0
            deleted = row["loc_deleted"] || 0
            revision = row["revision"]

            results[entity] ||= {entity: entity, added: 0, deleted: 0, revisions: Set.new}
            results[entity][:added] += added
            results[entity][:deleted] += deleted
            results[entity][:revisions] << revision
          end

          # Filter by minimum revisions and format results
          filtered_results = results.values.map do |result|
            next if result[:revisions].size < min_revs

            {
              entity: result[:entity],
              added: result[:added],
              deleted: result[:deleted],
              commits: result[:revisions].size
            }
          end.compact

          # Sort by total churn descending
          filtered_results.sort_by! { |r| -(r[:added] + r[:deleted]) }

          to_csv_data(filtered_results, %i[entity added deleted commits])
        end
      end

      # Ownership analysis - churn metrics per author per entity
      class Ownership < BaseAnalysis
        def analyze(dataset, _options = {})
          # Group by entity and author
          results = {}

          dataset.to_df.each_row do |row|
            entity = row["entity"]
            author = row["author"]
            added = row["loc_added"] || 0
            deleted = row["loc_deleted"] || 0

            key = [entity, author]
            results[key] ||= {entity: entity, author: author, added: 0, deleted: 0}
            results[key][:added] += added
            results[key][:deleted] += deleted
          end

          # Sort by entity, then by total contribution descending
          sorted_results = results.values.sort do |a, b|
            entity_comparison = a[:entity] <=> b[:entity]
            if entity_comparison.zero?
              total_b = b[:added] + b[:deleted]
              total_a = a[:added] + a[:deleted]
              total_b <=> total_a
            else
              entity_comparison
            end
          end

          to_csv_data(sorted_results, %i[entity author added deleted])
        end
      end

      # Main developer analysis - primary contributor per entity (by lines)
      class MainDeveloper < BaseAnalysis
        def analyze(dataset, options = {})
          min_revs = options[:min_revs] || 5

          # Group contributions by entity and author
          entity_contributions = {}
          entity_totals = {}

          dataset.to_df.each_row do |row|
            entity = row["entity"]
            author = row["author"]
            added = row["loc_added"] || 0
            row["loc_deleted"] || 0

            entity_contributions[entity] ||= {}
            entity_contributions[entity][author] ||= {added: 0, revisions: Set.new}
            entity_contributions[entity][author][:added] += added
            entity_contributions[entity][author][:revisions] << row["revision"]

            entity_totals[entity] ||= 0
            entity_totals[entity] += added
          end

          # Find main developer for each entity
          results = []

          entity_contributions.each do |entity, authors|
            total_revisions = authors.values.map { |data| data[:revisions] }.reduce(Set.new, &:|).size
            next if total_revisions < min_revs

            # Find author with most added lines (tie-break by author name alphabetically)
            main_author = authors.max_by { |author, data| [data[:added], author] }
            next unless main_author

            author_name, author_data = main_author
            total_added = entity_totals[entity]
            ownership = total_added.positive? ? (author_data[:added].to_f / total_added).round(2) : 0.0

            results << {
              entity: entity,
              "main-dev": author_name,
              added: author_data[:added],
              "total-added": total_added,
              ownership: ownership
            }
          end

          # Sort by entity name
          results.sort_by! { |r| r[:entity] }

          to_csv_data(results, %i[entity main-dev added total-added ownership])
        end
      end

      # Refactoring main developer - entities with frequent changes by main developer
      class RefactoringMainDeveloper < BaseAnalysis
        def analyze(dataset, options = {})
          min_revs = options[:min_revs] || 5

          # First find main developers
          main_dev_analysis = MainDeveloper.new
          main_devs_df = main_dev_analysis.analyze(dataset, options)

          # Convert to hash for lookup
          main_devs = {}
          main_devs_df.each_row do |row|
            main_devs[row[:entity]] = row[:main_dev]
          end

          # Count revisions by main developer per entity
          results = []

          main_devs.each do |entity, main_dev|
            entity_data = dataset.to_df.filter { |row| row[:entity] == entity && row[:author] == main_dev }
            main_dev_revisions = entity_data[:revision].uniq.size

            next if main_dev_revisions < min_revs

            results << {
              entity: entity,
              main_dev: main_dev,
              added: main_dev_revisions, # Number of revisions by main dev
              deleted: 0
            }
          end

          # Sort by number of revisions descending
          results.sort_by! { |r| -r[:added] }

          to_csv_data(results, %i[entity main_dev added deleted])
        end
      end
    end
  end
end
