# frozen_string_literal: true

RSpec.describe RubyMaat::Analysis::MergeCoupling do
  let(:analysis) { described_class.new }
  let(:default_options) do
    {
      min_revs: 1,
      min_shared_revs: 1,
      min_coupling: 1,
      max_coupling: 100,
      max_changeset_size: 30
    }
  end

  describe "#analyze" do
    context "with merge commits grouping related changes" do
      # Simulates a git history where merge commits group feature branch commits:
      # merge1 contains rev1 and rev2 (feature A touching file1, file2, file3)
      # merge2 contains rev3 and rev4 (feature B touching file1, file4)
      let(:records) do
        [
          # Merge commit 1 - groups a feature branch
          RubyMaat::ChangeRecord.new(
            entity: "file1.rb", author: "alice", date: "2023-01-01",
            revision: "merge1", message: "Merge pull request #10",
            merge_commit: true
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file2.rb", author: "alice", date: "2023-01-01",
            revision: "merge1", message: "Merge pull request #10",
            merge_commit: true
          ),
          # Non-merge commit following merge1 (part of the same PR)
          RubyMaat::ChangeRecord.new(
            entity: "file3.rb", author: "bob", date: "2023-01-01",
            revision: "rev1", message: "Add feature A part 1",
            merge_commit: false
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file1.rb", author: "bob", date: "2023-01-01",
            revision: "rev2", message: "Add feature A part 2",
            merge_commit: false
          ),
          # Merge commit 2 - groups another feature branch
          RubyMaat::ChangeRecord.new(
            entity: "file1.rb", author: "charlie", date: "2023-01-05",
            revision: "merge2", message: "Merge branch 'feature-b'",
            merge_commit: true
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file4.rb", author: "charlie", date: "2023-01-05",
            revision: "merge2", message: "Merge branch 'feature-b'",
            merge_commit: true
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file1.rb", author: "charlie", date: "2023-01-04",
            revision: "rev3", message: "Work on feature B",
            merge_commit: false
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file4.rb", author: "charlie", date: "2023-01-04",
            revision: "rev4", message: "More work on feature B",
            merge_commit: false
          )
        ]
      end

      let(:dataset) { RubyMaat::Dataset.from_changes(records) }

      it "groups changes by merge boundaries for coupling" do
        results = analysis.analyze(dataset, default_options)

        results_array = []
        results.each_row { |row| results_array << row.to_h }

        # file1 and file2 should be coupled (both in merge1 group)
        # file1 and file3 should be coupled (file3 is in merge1 group via rev1)
        coupled_with_file1 = results_array.select do |r|
          r["entity"] == "file1.rb" || r["coupled"] == "file1.rb"
        end.map do |r|
          (r["entity"] == "file1.rb") ? r["coupled"] : r["entity"]
        end

        expect(coupled_with_file1).to include("file2.rb")
        expect(coupled_with_file1).to include("file3.rb")
      end

      it "produces coupling between files in same merge group" do
        results = analysis.analyze(dataset, default_options)

        results_array = []
        results.each_row { |row| results_array << row.to_h }

        # file1 and file4 should be coupled via merge2 group
        file1_file4 = results_array.find do |r|
          (r["entity"] == "file1.rb" && r["coupled"] == "file4.rb") ||
            (r["entity"] == "file4.rb" && r["coupled"] == "file1.rb")
        end

        expect(file1_file4).not_to be_nil
      end
    end

    context "with standalone commits (no merges)" do
      let(:records) do
        [
          RubyMaat::ChangeRecord.new(
            entity: "file1.rb", author: "alice", date: "2023-01-01",
            revision: "rev1", message: "Change file1",
            merge_commit: false
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file2.rb", author: "alice", date: "2023-01-01",
            revision: "rev1", message: "Change file1",
            merge_commit: false
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file1.rb", author: "bob", date: "2023-01-02",
            revision: "rev2", message: "Change file1 again",
            merge_commit: false
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file2.rb", author: "bob", date: "2023-01-02",
            revision: "rev2", message: "Change file2 again",
            merge_commit: false
          )
        ]
      end

      let(:dataset) { RubyMaat::Dataset.from_changes(records) }

      it "treats each commit as its own group" do
        results = analysis.analyze(dataset, default_options)

        results_array = []
        results.each_row { |row| results_array << row.to_h }

        # file1 and file2 change together in rev1 and rev2, so they should be coupled
        coupling = results_array.find do |r|
          (r["entity"] == "file1.rb" && r["coupled"] == "file2.rb") ||
            (r["entity"] == "file2.rb" && r["coupled"] == "file1.rb")
        end

        expect(coupling).not_to be_nil
        expect(coupling["degree"]).to be > 0
      end
    end

    context "with nil merge_commit values (backward compatibility)" do
      let(:records) do
        [
          RubyMaat::ChangeRecord.new(
            entity: "file1.rb", author: "alice", date: "2023-01-01",
            revision: "rev1", message: "Change files"
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file2.rb", author: "alice", date: "2023-01-01",
            revision: "rev1", message: "Change files"
          )
        ]
      end

      let(:dataset) { RubyMaat::Dataset.from_changes(records) }

      it "handles records without merge_commit field" do
        results = analysis.analyze(dataset, default_options)

        results_array = []
        results.each_row { |row| results_array << row.to_h }

        expect(results_array.size).to eq(1)
      end
    end

    it "filters by minimum coupling threshold" do
      records = [
        RubyMaat::ChangeRecord.new(
          entity: "file1.rb", author: "alice", date: "2023-01-01",
          revision: "merge1", message: "Merge pull request #1", merge_commit: true
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file2.rb", author: "alice", date: "2023-01-01",
          revision: "merge1", message: "Merge pull request #1", merge_commit: true
        )
      ]
      dataset = RubyMaat::Dataset.from_changes(records)

      options = default_options.merge(min_coupling: 101)
      results = analysis.analyze(dataset, options)

      expect(results.count).to eq(0)
    end

    it "excludes large changesets" do
      records = (1..35).map do |i|
        RubyMaat::ChangeRecord.new(
          entity: "file#{i}.rb", author: "alice", date: "2023-01-01",
          revision: "merge1", message: "Merge pull request #1", merge_commit: true
        )
      end
      dataset = RubyMaat::Dataset.from_changes(records)

      results = analysis.analyze(dataset, default_options)

      expect(results.count).to eq(0)
    end

    it "includes verbose results when requested" do
      records = [
        RubyMaat::ChangeRecord.new(
          entity: "file1.rb", author: "alice", date: "2023-01-01",
          revision: "merge1", message: "Merge pull request #1", merge_commit: true
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file2.rb", author: "alice", date: "2023-01-01",
          revision: "merge1", message: "Merge pull request #1", merge_commit: true
        )
      ]
      dataset = RubyMaat::Dataset.from_changes(records)

      options = default_options.merge(verbose_results: true)
      results = analysis.analyze(dataset, options)

      expect(results.keys).to include("first-entity-revisions")
      expect(results.keys).to include("second-entity-revisions")
      expect(results.keys).to include("shared-revisions")
    end

    it "sorts results by coupling degree descending" do
      records = [
        RubyMaat::ChangeRecord.new(
          entity: "file1.rb", author: "alice", date: "2023-01-01",
          revision: "merge1", message: "Merge pull request #1", merge_commit: true
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file2.rb", author: "alice", date: "2023-01-01",
          revision: "merge1", message: "Merge pull request #1", merge_commit: true
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file3.rb", author: "alice", date: "2023-01-01",
          revision: "merge1", message: "Merge pull request #1", merge_commit: true
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file1.rb", author: "bob", date: "2023-01-02",
          revision: "merge2", message: "Merge branch 'fix'", merge_commit: true
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file2.rb", author: "bob", date: "2023-01-02",
          revision: "merge2", message: "Merge branch 'fix'", merge_commit: true
        )
      ]
      dataset = RubyMaat::Dataset.from_changes(records)

      results = analysis.analyze(dataset, default_options)

      results_array = []
      results.each_row { |row| results_array << row.to_h }

      degrees = results_array.map { |r| r["degree"] }
      expect(degrees).to eq(degrees.sort.reverse)
    end
  end
end
