# frozen_string_literal: true

RSpec.describe RubyMaat::Analysis::LogicalCoupling do
  # Create records where file1.rb and file2.rb change together frequently
  let(:sample_records) do
    [
      # Revision 1: file1 and file2 change together
      RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "alice", date: "2023-01-01", revision: "rev1"),
      RubyMaat::ChangeRecord.new(entity: "file2.rb", author: "alice", date: "2023-01-01", revision: "rev1"),

      # Revision 2: file1 and file2 change together again
      RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "bob", date: "2023-01-02", revision: "rev2"),
      RubyMaat::ChangeRecord.new(entity: "file2.rb", author: "bob", date: "2023-01-02", revision: "rev2"),

      # Revision 3: file1 and file3 change together
      RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "charlie", date: "2023-01-03", revision: "rev3"),
      RubyMaat::ChangeRecord.new(entity: "file3.rb", author: "charlie", date: "2023-01-03", revision: "rev3"),

      # Revision 4: only file1 changes
      RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "alice", date: "2023-01-04", revision: "rev4"),

      # Revision 5: file1 and file2 change together (third time)
      RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "bob", date: "2023-01-05", revision: "rev5"),
      RubyMaat::ChangeRecord.new(entity: "file2.rb", author: "bob", date: "2023-01-05", revision: "rev5")
    ]
  end

  let(:dataset) { RubyMaat::Dataset.from_changes(sample_records) }
  let(:analysis) { described_class.new }

  describe "#analyze" do
    it "calculates logical coupling between entities" do
      options = {
        min_revs: 1,
        min_shared_revs: 1,
        min_coupling: 1,
        max_coupling: 100,
        max_changeset_size: 30
      }

      results = analysis.analyze(dataset, options)

      results_array = []
      results.each_row { |row| results_array << row.to_h }

      # Should find coupling between file1.rb and file2.rb
      file1_file2_coupling = results_array.find do |r|
        r[:entity] == "file1.rb" && r[:coupled] == "file2.rb"
      end

      expect(file1_file2_coupling).not_to be_nil
      expect(file1_file2_coupling[:degree]).to be > 0
    end

    it "filters by minimum coupling threshold" do
      options = {
        min_revs: 1,
        min_shared_revs: 1,
        min_coupling: 90, # Very high threshold
        max_coupling: 100,
        max_changeset_size: 30
      }

      results = analysis.analyze(dataset, options)

      # Should have fewer or no results with high threshold
      expect(results.count).to be <= 1
    end

    it "filters by minimum shared revisions" do
      options = {
        min_revs: 1,
        min_shared_revs: 5, # High threshold - files need to change together 5+ times
        min_coupling: 1,
        max_coupling: 100,
        max_changeset_size: 30
      }

      results = analysis.analyze(dataset, options)

      # Should have no results since no files change together 5+ times
      expect(results.count).to eq(0)
    end

    it "excludes large changesets" do
      # Create a large changeset
      large_changeset_records = (1..35).map do |i|
        RubyMaat::ChangeRecord.new(
          entity: "file#{i}.rb",
          author: "alice",
          date: "2023-01-01",
          revision: "big_rev"
        )
      end

      large_dataset = RubyMaat::Dataset.from_changes(large_changeset_records)

      options = {
        min_revs: 1,
        min_shared_revs: 1,
        min_coupling: 1,
        max_coupling: 100,
        max_changeset_size: 30 # Smaller than the changeset
      }

      results = analysis.analyze(large_dataset, options)

      # Should have no results since the changeset is too large
      expect(results.count).to eq(0)
    end

    it "includes verbose results when requested" do
      options = {
        min_revs: 1,
        min_shared_revs: 1,
        min_coupling: 1,
        max_coupling: 100,
        max_changeset_size: 30,
        verbose_results: true
      }

      results = analysis.analyze(dataset, options)

      # Check if verbose columns are present
      expect(results.keys).to include(:first_entity_revisions)
      expect(results.keys).to include(:second_entity_revisions)
      expect(results.keys).to include(:shared_revisions)
    end

    it "sorts results by coupling degree descending" do
      options = {
        min_revs: 1,
        min_shared_revs: 1,
        min_coupling: 1,
        max_coupling: 100,
        max_changeset_size: 30
      }

      results = analysis.analyze(dataset, options)

      results_array = []
      results.each_row { |row| results_array << row.to_h }

      # Results should be sorted by degree descending
      degrees = results_array.map { |r| r[:degree] }
      expect(degrees).to eq(degrees.sort.reverse)
    end
  end
end
