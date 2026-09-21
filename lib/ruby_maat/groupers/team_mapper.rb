# frozen_string_literal: true

require "csv"

module RubyMaat
  module Groupers
    # Team mapper - maps individual authors to teams
    class TeamMapper
      def initialize(team_map_file)
        @team_map_file = team_map_file
        @author_to_team = load_team_mapping
      end

      def map(change_records)
        change_records.map do |record|
          team_name = @author_to_team[record.author] || record.author

          # Create new record with team name instead of individual author
          ChangeRecord.new(
            entity: record.entity,
            author: team_name,
            date: record.date,
            revision: record.revision,
            message: record.message,
            loc_added: record.loc_added,
            loc_deleted: record.loc_deleted
          )
        end
      end

      private

      def load_team_mapping
        mapping = {}

        CSV.foreach(@team_map_file, headers: true) do |row|
          author = row["author"] || row[0]
          team = row["team"] || row[1]

          next unless author && team

          mapping[author.strip] = team.strip
        end

        mapping
      rescue => e
        raise ArgumentError, "Failed to load team mapping file #{@team_map_file}: #{e.message}"
      end
    end
  end
end
