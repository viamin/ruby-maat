# frozen_string_literal: true

RSpec.describe RubyMaat::ChangeRecord do
  describe "#initialize" do
    it "creates a change record with required fields" do
      record = described_class.new(
        entity: "src/main.rb",
        author: "John Doe",
        date: "2023-01-15",
        revision: "abc123"
      )

      expect(record.entity).to eq("src/main.rb")
      expect(record.author).to eq("John Doe")
      expect(record.date).to eq(Date.parse("2023-01-15"))
      expect(record.revision).to eq("abc123")
    end

    it "accepts optional fields" do
      record = described_class.new(
        entity: "src/main.rb",
        author: "John Doe",
        date: "2023-01-15",
        revision: "abc123",
        message: "Fix bug",
        loc_added: 10,
        loc_deleted: 5
      )

      expect(record.message).to eq("Fix bug")
      expect(record.loc_added).to eq(10)
      expect(record.loc_deleted).to eq(5)
    end

    it "parses date strings correctly" do
      record = described_class.new(
        entity: "file.rb",
        author: "Jane",
        date: "2023-12-25",
        revision: "def456"
      )

      expect(record.date).to eq(Date.new(2023, 12, 25))
    end

    it "accepts Date objects" do
      date = Date.new(2023, 6, 15)
      record = described_class.new(
        entity: "file.rb",
        author: "Jane",
        date: date,
        revision: "def456"
      )

      expect(record.date).to eq(date)
    end

    it "raises error for invalid date" do
      expect do
        described_class.new(
          entity: "file.rb",
          author: "Jane",
          date: "invalid-date",
          revision: "def456"
        )
      end.to raise_error(ArgumentError, /Invalid date format/)
    end
  end

  describe "#to_h" do
    it "converts to hash representation" do
      record = described_class.new(
        entity: "src/main.rb",
        author: "John Doe",
        date: "2023-01-15",
        revision: "abc123",
        message: "Fix bug",
        loc_added: 10,
        loc_deleted: 5
      )

      hash = record.to_h

      expect(hash).to eq({
        entity: "src/main.rb",
        author: "John Doe",
        date: Date.parse("2023-01-15"),
        revision: "abc123",
        message: "Fix bug",
        loc_added: 10,
        loc_deleted: 5
      })
    end
  end

  describe "#==" do
    it "compares records for equality" do
      record1 = described_class.new(
        entity: "file.rb",
        author: "John",
        date: "2023-01-01",
        revision: "abc123"
      )

      record2 = described_class.new(
        entity: "file.rb",
        author: "John",
        date: "2023-01-01",
        revision: "abc123"
      )

      record3 = described_class.new(
        entity: "file.rb",
        author: "Jane",
        date: "2023-01-01",
        revision: "abc123"
      )

      expect(record1).to eq(record2)
      expect(record1).not_to eq(record3)
    end
  end
end
