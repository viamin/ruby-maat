# frozen_string_literal: true

module RubyMaat
  module Analysis
    module Effort
      # Entity effort analysis - revisions per author per entity
      class ByRevisions < BaseAnalysis
        def analyze(dataset, _options = {})
          # Group by entity and author, count revisions
          results = {}

          dataset.to_df.each_row do |row|
            entity = row["entity"]
            author = row["author"]
            revision = row["revision"]

            key = [entity, author]
            results[key] ||= {
              entity: entity,
              author: author,
              author_revs: Set.new,
              total_revs: Set.new
            }
            results[key][:author_revs] << revision
          end

          # Calculate total revisions per entity
          entity_totals = {}
          dataset.to_df.each_row do |row|
            entity = row["entity"]
            revision = row["revision"]

            entity_totals[entity] ||= Set.new
            entity_totals[entity] << revision
          end

          # Format results
          formatted_results = results.map do |(entity, author), data|
            {
              entity: entity,
              author: author,
              "author-revs": data[:author_revs].size,
              "total-revs": entity_totals[entity].size
            }
          end

          # Sort by entity, then by author revisions descending
          formatted_results.sort! do |a, b|
            entity_comparison = a[:entity] <=> b[:entity]
            entity_comparison.zero? ? b[:"author-revs"] <=> a[:"author-revs"] : entity_comparison
          end

          to_csv_data(formatted_results, %i[entity author author-revs total-revs])
        end
      end

      # Main developer by revisions - primary contributor per entity (by commit count)
      class MainDeveloperByRevisions < BaseAnalysis
        def analyze(dataset, options = {})
          min_revs = options[:min_revs] || 5

          # Group by entity and author, count revisions
          entity_authors = {}

          dataset.to_df.each_row do |row|
            entity = row["entity"]
            author = row["author"]
            revision = row["revision"]

            entity_authors[entity] ||= {}
            entity_authors[entity][author] ||= Set.new
            entity_authors[entity][author] << revision
          end

          # Find main developer for each entity
          results = []

          entity_authors.each do |entity, authors|
            total_revisions = authors.values.map(&:size).sum
            next if total_revisions < min_revs

            # Find author with most revisions
            main_author, revisions = authors.max_by { |_author, revs| revs.size }

            total_revisions = authors.values.map(&:size).sum

            results << {
              entity: entity,
              "main-dev": main_author,
              added: revisions.size, # Number of revisions by main dev
              "total-added": total_revisions,
              ownership: total_revisions.positive? ? (revisions.size.to_f / total_revisions).round(2) : 0.0
            }
          end

          # Sort by number of revisions descending
          results.sort_by! { |r| -r[:added] }

          to_csv_data(results, %i[entity main-dev added total-added ownership])
        end
      end

      # Fragmentation analysis - measures ownership distribution (fractal value)
      class Fragmentation < BaseAnalysis
        def analyze(dataset, options = {})
          min_revs = options[:min_revs] || 5

          # Group by entity, count contributions per author
          entity_contributions = {}

          dataset.to_df.each_row do |row|
            entity = row["entity"]
            author = row["author"]
            revision = row["revision"]

            entity_contributions[entity] ||= {}
            entity_contributions[entity][author] ||= Set.new
            entity_contributions[entity][author] << revision
          end

          # Calculate fragmentation (fractal value) for each entity
          results = []

          entity_contributions.each do |entity, authors|
            total_revisions = authors.values.map(&:size).sum
            next if total_revisions < min_revs

            # Calculate fractal value: 1 - sum(p_i^2) where p_i is proportion of each author
            sum_of_squares = authors.values.map do |revisions|
              proportion = revisions.size.to_f / total_revisions
              proportion**2
            end.sum

            fractal_value = 1.0 - sum_of_squares

            results << {
              entity: entity,
              fractal_value: fractal_value.round(3)
            }
          end

          # Sort by fractal value descending (most fragmented first)
          results.sort_by! { |r| -r[:fractal_value] }

          to_csv_data(results, %i[entity fractal_value])
        end
      end
    end
  end
end
