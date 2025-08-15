# frozen_string_literal: true

module RubyMaat
  module Analysis
    # Summary analysis - provides high-level overview of repository statistics
    class Summary < BaseAnalysis
      def analyze(dataset, _options = {})
        df = dataset.to_df

        if df.empty?
          results = [
            {statistic: "number-of-commits", value: 0},
            {statistic: "number-of-entities", value: 0},
            {statistic: "number-of-entities-changed", value: 0},
            {statistic: "number-of-authors", value: 0}
          ]
        else
          # Collect data manually to avoid DataFrame API issues
          revisions = []
          entities = []
          authors = []
          total_changes = 0

          df.each_row do |row|
            revisions << row["revision"]
            entities << row["entity"]
            authors << row["author"]
            total_changes += 1
          end

          results = [
            {statistic: "number-of-commits", value: revisions.uniq.size},
            {statistic: "number-of-entities", value: entities.uniq.size},
            {statistic: "number-of-entities-changed", value: total_changes},
            {statistic: "number-of-authors", value: authors.uniq.size}
          ]
        end

        to_csv_data(results, %i[statistic value])
      end
    end
  end
end
