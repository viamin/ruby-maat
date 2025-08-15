# frozen_string_literal: true

module RubyMaat
  # Represents a single change/modification record from VCS
  # This is the fundamental data structure that flows through the entire pipeline
  class ChangeRecord
    attr_reader :entity, :author, :date, :revision, :message, :loc_added, :loc_deleted

    def initialize(entity:, author:, date:, revision:, message: nil, loc_added: nil, loc_deleted: nil)
      @entity = entity
      @author = author
      @date = parse_date(date)
      @revision = revision
      @message = message
      @loc_added = loc_added&.to_i
      @loc_deleted = loc_deleted&.to_i
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

    private

    def parse_date(date_input)
      case date_input
      when Date
        date_input
      when String
        Date.parse(date_input)
      else
        raise ArgumentError, "Date must be a Date object or parseable string, got #{date_input.class}"
      end
    rescue Date::Error
      raise ArgumentError, "Invalid date format: #{date_input}"
    end
  end
end
