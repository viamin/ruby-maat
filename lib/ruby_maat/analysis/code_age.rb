# frozen_string_literal: true

module RubyMaat
  module Analysis
    # Code age analysis - measures how long since each entity was last modified
    class CodeAge < BaseAnalysis
      def analyze(dataset, options = {})
        reference_date = options[:age_time_now] || Date.today

        # Find the latest modification date for each entity
        entity_latest_dates = {}

        dataset.to_df.each_row do |row|
          entity = row["entity"]
          date = row["date"]

          entity_latest_dates[entity] = date if entity_latest_dates[entity].nil? || date > entity_latest_dates[entity]
        end

        # Calculate age in months for each entity
        results = entity_latest_dates.map do |entity, last_date|
          months_old = calculate_months_between(last_date, reference_date)

          {
            entity: entity,
            "age-months": months_old
          }
        end

        # Sort by age descending (oldest first)
        results.sort_by! { |r| -r[:"age-months"] }

        to_csv_data(results, %i[entity age-months])
      end

      private

      def calculate_months_between(start_date, end_date)
        return 0 if start_date >= end_date

        years = end_date.year - start_date.year
        months = end_date.month - start_date.month

        total_months = (years * 12) + months

        # Adjust if the day hasn't been reached yet in the end month
        total_months -= 1 if end_date.day < start_date.day

        [total_months, 0].max
      end
    end
  end
end
