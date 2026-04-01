# frozen_string_literal: true

module RubyMaat
  # Represents a single change/modification record from VCS
  # This is the fundamental data structure that flows through the entire pipeline
  class ChangeRecord
    attr_reader :entity, :author, :date, :revision, :message, :loc_added, :loc_deleted, :parent_revisions

    def initialize(entity:, author:, date:, revision:, message: nil, loc_added: nil, loc_deleted: nil,
      parent_revisions: nil)
      @entity = entity
      @author = author
      @date = date.is_a?(Date) ? date : Date.parse(date)
      @revision = revision
      @message = message
      @loc_added = loc_added.to_i if loc_added && (!loc_added.is_a?(Float) || !loc_added.nan?)
      @loc_deleted = loc_deleted.to_i if loc_deleted && (!loc_deleted.is_a?(Float) || !loc_deleted.nan?)
      @parent_revisions = parent_revisions
    end

    def merge_commit?
      parent_revisions.is_a?(Array) && parent_revisions.size >= 2
    end

    def to_h
      {
        entity: entity,
        author: author,
        date: date,
        revision: revision,
        message: message,
        loc_added: loc_added,
        loc_deleted: loc_deleted
      }
    end

    def ==(other)
      other.is_a?(ChangeRecord) &&
        entity == other.entity &&
        author == other.author &&
        date == other.date &&
        revision == other.revision
    end

    def hash
      [entity, author, date, revision].hash
    end

    def eql?(other)
      self == other
    end
  end
end
