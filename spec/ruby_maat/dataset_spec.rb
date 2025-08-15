# frozen_string_literal: true

RSpec.describe RubyMaat::Dataset do
  let(:sample_records) do
    [
      RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "alice", date: "2023-01-01", revision: "rev1"),
      RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "bob", date: "2023-01-02", revision: "rev2"),
      RubyMaat::ChangeRecord.new(entity: "file2.rb", author: "alice", date: "2023-01-03", revision: "rev3"),
      RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "alice", date: "2023-01-04", revision: "rev4")
    ]
  end

  describe "#initialize" do
    it "creates empty dataset" do
      dataset = described_class.new
      expect(dataset.empty?).to be true
    end

    it "creates dataset from change records" do
      dataset = described_class.new(sample_records)
      expect(dataset.size).to eq(4)
      expect(dataset.empty?).to be false
    end
  end

  describe ".from_changes" do
    it "creates dataset from change records" do
      dataset = described_class.from_changes(sample_records)
      expect(dataset.size).to eq(4)
    end
  end

  describe "#entities" do
    it "returns unique entities" do
      dataset = described_class.from_changes(sample_records)
      entities = dataset.entities

      expect(entities).to contain_exactly("file1.rb", "file2.rb")
    end
  end

  describe "#authors" do
    it "returns unique authors" do
      dataset = described_class.from_changes(sample_records)
      authors = dataset.authors

      expect(authors).to contain_exactly("alice", "bob")
    end
  end

  describe "#filter_min_revisions" do
    it "filters entities with fewer than minimum revisions" do
      dataset = described_class.from_changes(sample_records)
      filtered = dataset.filter_min_revisions(3)

      # file1.rb has 3 revisions (rev1, rev2, rev4), file2.rb has 1 (rev3)
      entities = filtered.entities
      expect(entities).to contain_exactly("file1.rb")
    end
  end

  describe "#coupling_pairs" do
    it "finds entities that changed together" do
      # Add records that change together in same revision
      records = [
        RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "alice", date: "2023-01-01", revision: "rev1"),
        RubyMaat::ChangeRecord.new(entity: "file2.rb", author: "alice", date: "2023-01-01", revision: "rev1"),
        RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "bob", date: "2023-01-02", revision: "rev2"),
        RubyMaat::ChangeRecord.new(entity: "file2.rb", author: "bob", date: "2023-01-02", revision: "rev2")
      ]

      dataset = described_class.from_changes(records)
      pairs = dataset.coupling_pairs

      expect(pairs).to include(["file1.rb", "file2.rb"])
    end
  end

  describe "#shared_revisions_count" do
    it "counts shared revisions between entities" do
      records = [
        RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "alice", date: "2023-01-01", revision: "rev1"),
        RubyMaat::ChangeRecord.new(entity: "file2.rb", author: "alice", date: "2023-01-01", revision: "rev1"),
        RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "bob", date: "2023-01-02", revision: "rev2"),
        RubyMaat::ChangeRecord.new(entity: "file2.rb", author: "bob", date: "2023-01-02", revision: "rev2"),
        RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "charlie", date: "2023-01-03", revision: "rev3")
      ]

      dataset = described_class.from_changes(records)
      shared_count = dataset.shared_revisions_count("file1.rb", "file2.rb")

      expect(shared_count).to eq(2) # rev1 and rev2
    end
  end

  describe "#revision_count" do
    it "counts revisions for an entity" do
      dataset = described_class.from_changes(sample_records)
      count = dataset.revision_count("file1.rb")

      expect(count).to eq(3) # rev1, rev2, rev4
    end
  end

  describe "#latest_date_by_entity" do
    it "finds latest modification date per entity" do
      dataset = described_class.from_changes(sample_records)
      latest_dates = dataset.latest_date_by_entity

      # Convert to hash for easier testing
      dates_hash = {}
      latest_dates.to_a.each { |row| dates_hash[row["entity"]] = row["max_date"] }

      expect(dates_hash["file1.rb"]).to eq(Date.parse("2023-01-04"))
      expect(dates_hash["file2.rb"]).to eq(Date.parse("2023-01-03"))
    end
  end
end
