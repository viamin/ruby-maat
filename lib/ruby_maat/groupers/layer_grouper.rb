# frozen_string_literal: true

module RubyMaat
  module Groupers
    # Layer grouper - maps individual files to architectural layers using regex patterns
    class LayerGrouper
      def initialize(grouping_file)
        @grouping_file = grouping_file
        @patterns = load_grouping_patterns
      end

      def group(change_records)
        change_records.map do |record|
          new_entity = map_entity_to_layer(record.entity)

          # Create new record with mapped entity name
          ChangeRecord.new(
            entity: new_entity,
            author: record.author,
            date: record.date,
            revision: record.revision,
            message: record.message,
            loc_added: record.loc_added,
            loc_deleted: record.loc_deleted
          )
        end
      end

      private

      def load_grouping_patterns
        patterns = []

        File.foreach(@grouping_file) do |line|
          line = line.strip
          next if line.empty? || line.start_with?("#")

          if line.include?("=>")
            pattern_str, layer_name = line.split("=>", 2)
            pattern_str = pattern_str.strip
            layer_name = layer_name.strip

            begin
              regex = Regexp.new(pattern_str)
              patterns << {regex: regex, layer: layer_name}
            rescue RegexpError => e
              warn "Invalid regex pattern '#{pattern_str}': #{e.message}"
            end
          end
        end

        patterns
      rescue => e
        raise ArgumentError, "Failed to load grouping file #{@grouping_file}: #{e.message}"
      end

      def map_entity_to_layer(entity)
        @patterns.each do |pattern_info|
          return pattern_info[:layer] if entity.match?(pattern_info[:regex])
        end

        # If no pattern matches, return the original entity name
        entity
      end
    end
  end
end
