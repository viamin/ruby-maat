# frozen_string_literal: true

module RubyMaat
  module Analysis
    # Sum of coupling analysis - aggregated coupling metrics per entity
    class SumOfCoupling < BaseAnalysis
      def analyze(dataset, options = {})
        # First run the logical coupling analysis to get coupling data
        coupling_analysis = LogicalCoupling.new
        coupling_results = coupling_analysis.analyze(dataset, options)

        # If no coupling results, return empty
        return to_csv_data([], %i[entity soc]) if coupling_results.empty?

        # Aggregate coupling degrees per entity
        entity_coupling_sums = Hash.new(0)

        coupling_results.each_row do |row|
          entity = row["entity"]
          coupled = row["coupled"]
          degree = row["degree"]

          # Add coupling for both directions
          entity_coupling_sums[entity] += degree
          entity_coupling_sums[coupled] += degree
        end

        # Calculate sum of coupling for each entity
        results = entity_coupling_sums.map do |entity, total_coupling|
          {
            entity: entity,
            soc: total_coupling
          }
        end

        # Sort by sum of coupling descending
        results.sort_by! { |r| -r[:soc] }

        to_csv_data(results, %i[entity soc])
      end
    end
  end
end
