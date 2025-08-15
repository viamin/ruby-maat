# frozen_string_literal: true

RSpec.describe RubyMaat::Analysis::Authors do
  let(:sample_records) do
    [
      RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "alice", date: "2023-01-01", revision: "rev1"),
      RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "bob", date: "2023-01-02", revision: "rev2"),
      RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "charlie", date: "2023-01-03", revision: "rev3"),
      RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "alice", date: "2023-01-04", revision: "rev4"),
      RubyMaat::ChangeRecord.new(entity: "file1.rb", author: "bob", date: "2023-01-05", revision: "rev5"),
      RubyMaat::ChangeRecord.new(entity: "file2.rb", author: "alice", date: "2023-01-06", revision: "rev6"),
      RubyMaat::ChangeRecord.new(entity: "file2.rb", author: "bob", date: "2023-01-07", revision: "rev7")
    ]
  end

  let(:dataset) { RubyMaat::Dataset.from_changes(sample_records) }
  let(:analysis) { described_class.new }

  describe "#analyze" do
    it "counts distinct authors per entity" do
      results = analysis.analyze(dataset)

      # Convert to array of hashes for easier testing
      results_array = []
      results.each_row { |row| results_array << row.to_h }

      file1_result = results_array.find { |r| r[:entity] == "file1.rb" }
      file2_result = results_array.find { |r| r[:entity] == "file2.rb" }

      expect(file1_result[:n_authors]).to eq(3) # alice, bob, charlie
      expect(file1_result[:n_revs]).to eq(5)    # rev1, rev2, rev3, rev4, rev5

      expect(file2_result[:n_authors]).to eq(2) # alice, bob
      expect(file2_result[:n_revs]).to eq(2)    # rev6, rev7
    end

    it "sorts results by number of authors descending" do
      results = analysis.analyze(dataset)

      results_array = []
      results.each_row { |row| results_array << row.to_h }

      expect(results_array.first[:entity]).to eq("file1.rb") # 3 authors
      expect(results_array.last[:entity]).to eq("file2.rb")  # 2 authors
    end

    it "filters by minimum revisions" do
      options = {min_revs: 3}
      results = analysis.analyze(dataset, options)

      results_array = []
      results.each_row { |row| results_array << row.to_h }

      # Only file1.rb has >= 3 revisions
      expect(results_array.size).to eq(1)
      expect(results_array.first[:entity]).to eq("file1.rb")
    end

    it "handles empty dataset" do
      empty_dataset = RubyMaat::Dataset.new
      results = analysis.analyze(empty_dataset)

      expect(results.count).to eq(0)
    end
  end
end
