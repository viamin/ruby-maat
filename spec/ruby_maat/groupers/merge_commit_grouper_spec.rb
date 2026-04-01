# frozen_string_literal: true

RSpec.describe RubyMaat::Groupers::MergeCommitGrouper do
  let(:grouper) { described_class.new }

  describe "#group" do
    let(:merge_branch_records) do
      [
        RubyMaat::ChangeRecord.new(
          entity: "file1.rb", author: "alice", date: "2023-01-05", revision: "merge1",
          parent_revisions: %w[main1 feat2]
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file2.rb", author: "alice", date: "2023-01-05", revision: "merge1",
          parent_revisions: %w[main1 feat2]
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file1.rb", author: "bob", date: "2023-01-04", revision: "feat2",
          parent_revisions: %w[feat1]
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file3.rb", author: "bob", date: "2023-01-03", revision: "feat1",
          parent_revisions: %w[main1]
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file4.rb", author: "charlie", date: "2023-01-01", revision: "main1",
          parent_revisions: %w[main0]
        )
      ]
    end

    it "groups feature branch commits under their merge commit" do
      result = grouper.group(merge_branch_records)

      feat2_record = result.find { |r| r.entity == "file1.rb" && r.author == "bob" }
      expect(feat2_record.revision).to eq("merge1")

      feat1_record = result.find { |r| r.entity == "file3.rb" }
      expect(feat1_record.revision).to eq("merge1")

      merge_records = result.select { |r| r.revision == "merge1" }
      expect(merge_records.size).to eq(4)

      main_record = result.find { |r| r.entity == "file4.rb" }
      expect(main_record.revision).to eq("main1")
    end

    it "handles multiple merge commits" do
      records = [
        # Second merge
        RubyMaat::ChangeRecord.new(
          entity: "file_b.rb", author: "alice", date: "2023-01-10", revision: "merge2",
          parent_revisions: %w[merge1 feat_b1]
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file_b.rb", author: "bob", date: "2023-01-09", revision: "feat_b1",
          parent_revisions: %w[merge1]
        ),
        # First merge
        RubyMaat::ChangeRecord.new(
          entity: "file_a.rb", author: "alice", date: "2023-01-05", revision: "merge1",
          parent_revisions: %w[main0 feat_a1]
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file_a.rb", author: "bob", date: "2023-01-04", revision: "feat_a1",
          parent_revisions: %w[main0]
        )
      ]

      result = grouper.group(records)

      feat_a = result.find { |r| r.author == "bob" && r.entity == "file_a.rb" }
      expect(feat_a.revision).to eq("merge1")

      feat_b = result.find { |r| r.author == "bob" && r.entity == "file_b.rb" }
      expect(feat_b.revision).to eq("merge2")
    end

    it "returns records unchanged when no parent info is available" do
      records = [
        RubyMaat::ChangeRecord.new(
          entity: "file1.rb", author: "alice", date: "2023-01-01", revision: "rev1"
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file2.rb", author: "bob", date: "2023-01-02", revision: "rev2"
        )
      ]

      result = grouper.group(records)

      expect(result.map(&:revision)).to eq(%w[rev1 rev2])
    end

    it "returns records unchanged when there are no merge commits" do
      records = [
        RubyMaat::ChangeRecord.new(
          entity: "file1.rb", author: "alice", date: "2023-01-01", revision: "rev1",
          parent_revisions: %w[rev0]
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file2.rb", author: "bob", date: "2023-01-02", revision: "rev2",
          parent_revisions: %w[rev1]
        )
      ]

      result = grouper.group(records)

      expect(result.map(&:revision)).to eq(%w[rev1 rev2])
    end

    it "preserves record attributes when rewriting revision" do
      records = [
        RubyMaat::ChangeRecord.new(
          entity: "file1.rb", author: "alice", date: "2023-01-05", revision: "merge1",
          loc_added: 10, loc_deleted: 5, parent_revisions: %w[main1 feat1]
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file2.rb", author: "bob", date: "2023-01-04", revision: "feat1",
          loc_added: 20, loc_deleted: 3, message: "Add feature",
          parent_revisions: %w[main1]
        )
      ]

      result = grouper.group(records)
      rewritten = result.find { |r| r.author == "bob" }

      expect(rewritten.revision).to eq("merge1")
      expect(rewritten.entity).to eq("file2.rb")
      expect(rewritten.author).to eq("bob")
      expect(rewritten.date).to eq(Date.parse("2023-01-04"))
      expect(rewritten.loc_added).to eq(20)
      expect(rewritten.loc_deleted).to eq(3)
      expect(rewritten.message).to eq("Add feature")
    end

    it "handles feature branch commits not present in the log" do
      records = [
        # Merge commit references a feature tip that's not in the log
        RubyMaat::ChangeRecord.new(
          entity: "file1.rb", author: "alice", date: "2023-01-05", revision: "merge1",
          parent_revisions: %w[main1 missing_feat]
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file2.rb", author: "bob", date: "2023-01-01", revision: "main1",
          parent_revisions: %w[main0]
        )
      ]

      result = grouper.group(records)

      # Nothing should be rewritten since feature commits aren't in the log
      expect(result.map(&:revision)).to eq(%w[merge1 main1])
    end
  end
end
