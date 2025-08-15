# frozen_string_literal: true

require "rover"

module RubyMaat
  # Wrapper around Rover DataFrame to provide domain-specific operations
  # This replaces Incanter datasets from the Clojure version
  class Dataset
    def initialize(change_records = [])
      @data = build_dataframe(change_records)
    end

    def self.from_changes(change_records)
      new(change_records)
    end

    def to_df
      @data
    end

    # Group by entity and count distinct authors
    def group_by_entity_count_authors
      @data.group(:entity).count(:author, name: "n_authors")
    end

    # Group by entity and count revisions
    def group_by_entity_count_revisions
      @data.group(:entity).count(:revision, name: "n_revs")
    end

    # Group by author and sum churn metrics
    def group_by_author_sum_churn
      @data.group(:author).sum(%i[loc_added loc_deleted])
    end

    # Group by entity and sum churn metrics
    def group_by_entity_sum_churn
      @data.group(:entity).sum(%i[loc_added loc_deleted])
    end

    # Get all entities (files)
    def entities
      return [] if @data.none?

      @data[:entity].uniq
    end

    # Get all authors
    def authors
      return [] if @data.none?

      @data[:author].uniq
    end

    # Filter by minimum revisions
    def filter_min_revisions(min_revs)
      # Group by entity and count revisions
      entity_revision_counts = {}
      @data.each_row do |row|
        entity = row[:entity]
        revision = row[:revision]
        entity_revision_counts[entity] ||= Set.new
        entity_revision_counts[entity] << revision
      end

      # Find entities with enough revisions
      entities_to_keep = entity_revision_counts.select { |_, revisions| revisions.size >= min_revs }.keys

      # Filter data to only include those entities
      filtered_records = []
      @data.each_row do |row|
        filtered_records << row.to_h if entities_to_keep.include?(row[:entity])
      end

      # Build new dataset from filtered records
      change_records = filtered_records.map do |record|
        ChangeRecord.new(
          entity: record[:entity],
          author: record[:author],
          date: record[:date],
          revision: record[:revision],
          message: record[:message],
          loc_added: record[:loc_added],
          loc_deleted: record[:loc_deleted]
        )
      end

      Dataset.from_changes(change_records)
    end

    # Get coupling pairs (combinations of entities that changed together)
    def coupling_pairs
      # Group by revision to find entities that changed together
      revision_entities = {}

      @data.each_row do |row|
        revision = row[:revision]
        entity = row[:entity]

        revision_entities[revision] ||= []
        revision_entities[revision] << entity unless revision_entities[revision].include?(entity)
      end

      pairs = []
      revision_entities.each_value do |entities|
        entities.combination(2) do |entity1, entity2|
          pairs << [entity1, entity2]
        end
      end

      pairs
    end

    # Count shared revisions between entity pairs
    def shared_revisions_count(entity1, entity2)
      entity1_revs = Set.new
      entity2_revs = Set.new

      @data.each_row do |row|
        if row[:entity] == entity1
          entity1_revs << row[:revision]
        elsif row[:entity] == entity2
          entity2_revs << row[:revision]
        end
      end

      (entity1_revs & entity2_revs).size
    end

    # Get revision count for an entity
    def revision_count(entity)
      revisions = Set.new
      @data.each_row do |row|
        revisions << row[:revision] if row[:entity] == entity
      end
      revisions.size
    end

    # Get unique dates
    def unique_dates
      @data[:date].uniq.sort
    end

    # Filter by date range
    def filter_date_range(start_date, end_date)
      filtered_records = []
      @data.each_row do |row|
        next unless row[:date].between?(start_date, end_date)

        filtered_records << ChangeRecord.new(
          entity: row[:entity],
          author: row[:author],
          date: row[:date],
          revision: row[:revision],
          message: row[:message],
          loc_added: row[:loc_added],
          loc_deleted: row[:loc_deleted]
        )
      end

      Dataset.from_changes(filtered_records)
    end

    # Get latest date for each entity (for age analysis)
    def latest_date_by_entity
      @data.group(:entity).max(:date)
    end

    def size
      @data.count
    end

    def empty?
      @data.none?
    end

    private

    def build_dataframe(change_records)
      return Rover::DataFrame.new if change_records.empty?

      data_hash = {
        entity: [],
        author: [],
        date: [],
        revision: [],
        message: [],
        loc_added: [],
        loc_deleted: []
      }

      change_records.each do |record|
        data_hash[:entity] << record.entity
        data_hash[:author] << record.author
        data_hash[:date] << record.date
        data_hash[:revision] << record.revision
        data_hash[:message] << record.message
        data_hash[:loc_added] << record.loc_added
        data_hash[:loc_deleted] << record.loc_deleted
      end

      Rover::DataFrame.new(data_hash)
    end
  end
end
