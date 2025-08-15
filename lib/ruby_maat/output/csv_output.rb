# frozen_string_literal: true

require "csv"

module RubyMaat
  module Output
    # CSV output handler - formats and writes analysis results as CSV
    class CsvOutput
      def initialize(output_file = nil, max_rows = nil)
        @output_file = output_file
        @max_rows = max_rows
      end

      def write(dataframe)
        # Convert dataframe to CSV
        output_stream = @output_file ? File.open(@output_file, "w") : $stdout

        begin
          write_csv(dataframe, output_stream)
        ensure
          output_stream.close if @output_file
        end
      end

      private

      def write_csv(dataframe, stream)
        # Write CSV
        csv = CSV.new(stream)

        # Get column names (even empty dataframes should have column structure)
        columns = dataframe.keys

        # Write header
        csv << columns

        # Write data rows (skip if empty)
        return if dataframe.empty?

        row_count = 0
        dataframe.each_row do |row|
          break if @max_rows && row_count >= @max_rows

          csv_row = columns.map { |col| format_value(row[col]) }
          csv << csv_row
          row_count += 1
        end
      end

      def format_value(value)
        case value
        when Date
          value.strftime("%Y-%m-%d")
        when Float
          # Round floats to reasonable precision
          value.round(3)
        when NilClass
          ""
        else
          value.to_s
        end
      end
    end
  end
end
