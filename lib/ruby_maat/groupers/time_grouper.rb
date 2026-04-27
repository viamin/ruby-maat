# frozen_string_literal: true

module RubyMaat
  module Groupers
    # Time grouper - aggregates commits within temporal periods
    class TimeGrouper
      def initialize(temporal_period)
        @temporal_period = temporal_period
      end

      def group(change_records)
        # For now, implement daily aggregation (group commits by day)
        # The temporal_period parameter could be extended for other periods

        grouped_by_date_and_entity = {}

        change_records.each do |record|
          date = record.date
          entity = record.entity

          key = [date, entity]
          grouped_by_date_and_entity[key] ||= []
          grouped_by_date_and_entity[key] << record
        end

        # Create aggregated records for each group
        aggregated_records = []

        grouped_by_date_and_entity.each do |(date, entity), records|
          # Aggregate the records for this date/entity combination
          aggregated_record = aggregate_records(records, date, entity)
          aggregated_records << aggregated_record
        end

        aggregated_records
      end

      private

      def aggregate_records(records, date, entity)
        # Use the first record as the base
        first_record = records.first

        # Aggregate numeric values
        total_added = records.sum { |r| r.loc_added || 0 }
        total_deleted = records.sum { |r| r.loc_deleted || 0 }

        # Combine commit messages
        messages = records.filter_map(&:message).uniq
        combined_message = messages.join("; ")

        # Prefer a merge commit as the representative record so that
        # revision and merge_commit stay internally consistent.
        representative = records.find { |r| r.merge_commit } || first_record

        ChangeRecord.new(
          entity: entity,
          author: representative.author,
          date: date,
          revision: representative.revision,
          message: combined_message,
          loc_added: total_added,
          loc_deleted: total_deleted,
          merge_commit: representative.merge_commit
        )
      end
    end
  end
end
