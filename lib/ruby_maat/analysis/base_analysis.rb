# frozen_string_literal: true

module RubyMaat
  module Analysis
    # Base class for all analysis modules
    class BaseAnalysis
      def analyze(dataset, options = {})
        raise NotImplementedError, "Subclasses must implement analyze method"
      end

      protected

      # Filter dataset by minimum revisions threshold
      def filter_by_min_revisions(dataset, min_revs)
        return dataset if min_revs <= 1

        dataset.filter_min_revisions(min_revs)
      end

      # Helper to convert analysis results to CSV-compatible format
      def to_csv_data(results, columns)
        if results.empty?
          # Create empty dataframe with proper column structure
          empty_data = {}
          columns.each { |col| empty_data[col] = [] }
          return Rover::DataFrame.new(empty_data)
        end

        if results.is_a?(Rover::DataFrame)
          # Already a dataframe
          results
        elsif results.first.is_a?(Hash)
          # Array of hashes
          Rover::DataFrame.new(results)
        else
          # Custom data structure - convert to hash format
          data = results.map { |item| format_row(item, columns) }
          Rover::DataFrame.new(data)
        end
      end

      def format_row(item, columns)
        if item.respond_to?(:to_h)
          item.to_h.slice(*columns)
        else
          # Assume item is an array matching column order
          columns.zip(item).to_h
        end
      end

      # Mathematical utilities
      def safe_divide(numerator, denominator)
        return 0 if denominator.nil? || denominator.zero?

        (numerator.to_f / denominator).round(2)
      end

      def percentage(part, total)
        (safe_divide(part, total) * 100).round(0)
      end

      # Calculate average of two numbers
      def average(first_value, second_value)
        return 0 if first_value.nil? || second_value.nil?

        ((first_value + second_value) / 2.0).round(1)
      end
    end
  end
end
