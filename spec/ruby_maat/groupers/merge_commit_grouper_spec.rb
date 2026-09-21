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

    context "with multiple merge commits" do
      let(:multi_merge_records) do
        [
          RubyMaat::ChangeRecord.new(
            entity: "file_b.rb", author: "alice", date: "2023-01-10", revision: "merge2",
            parent_revisions: %w[merge1 feat_b1]
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file_b.rb", author: "bob", date: "2023-01-09", revision: "feat_b1",
            parent_revisions: %w[merge1]
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file_a.rb", author: "alice", date: "2023-01-05", revision: "merge1",
            parent_revisions: %w[main0 feat_a1]
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file_a.rb", author: "bob", date: "2023-01-04", revision: "feat_a1",
            parent_revisions: %w[main0]
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file_base.rb", author: "charlie", date: "2023-01-01", revision: "main0",
            parent_revisions: []
          )
        ]
      end

      it "groups each feature branch under its respective merge" do
        result = grouper.group(multi_merge_records)

        feat_a = result.find { |r| r.author == "bob" && r.entity == "file_a.rb" }
        expect(feat_a.revision).to eq("merge1")

        feat_b = result.find { |r| r.author == "bob" && r.entity == "file_b.rb" }
        expect(feat_b.revision).to eq("merge2")
      end
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

    context "when preserving record attributes" do
      let(:attribute_records) do
        [
          RubyMaat::ChangeRecord.new(
            entity: "file1.rb", author: "alice", date: "2023-01-05", revision: "merge1",
            loc_added: 10, loc_deleted: 5, parent_revisions: %w[main1 feat1]
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file2.rb", author: "bob", date: "2023-01-04", revision: "feat1",
            loc_added: 20, loc_deleted: 3, message: "Add feature",
            parent_revisions: %w[main1]
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file0.rb", author: "charlie", date: "2023-01-01", revision: "main1",
            parent_revisions: %w[main0]
          )
        ]
      end

      it "preserves record attributes when rewriting revision" do
        result = grouper.group(attribute_records)
        rewritten = result.find { |r| r.author == "bob" }

        expect(rewritten.revision).to eq("merge1")
        expect(rewritten.entity).to eq("file2.rb")
        expect(rewritten.author).to eq("bob")
        expect(rewritten.date).to eq(Date.parse("2023-01-05"))
        expect(rewritten.loc_added).to eq(20)
        expect(rewritten.loc_deleted).to eq(3)
        expect(rewritten.message).to eq("Add feature")
        expect(rewritten.parent_revisions).to eq(%w[main1])
      end
    end

    context "when rewriting dates" do
      let(:date_rewrite_records) do
        [
          RubyMaat::ChangeRecord.new(
            entity: "file1.rb", author: "alice", date: "2023-01-10", revision: "merge1",
            parent_revisions: %w[main1 feat2]
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file2.rb", author: "bob", date: "2023-01-08", revision: "feat2",
            parent_revisions: %w[feat1]
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file3.rb", author: "bob", date: "2023-01-06", revision: "feat1",
            parent_revisions: %w[main1]
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file0.rb", author: "charlie", date: "2023-01-01", revision: "main1",
            parent_revisions: %w[main0]
          )
        ]
      end

      it "rewrites feature-branch dates to the merge commit date" do
        result = grouper.group(date_rewrite_records)

        feat2_record = result.find { |r| r.entity == "file2.rb" }
        expect(feat2_record.date).to eq(Date.parse("2023-01-10"))

        feat1_record = result.find { |r| r.entity == "file3.rb" }
        expect(feat1_record.date).to eq(Date.parse("2023-01-10"))

        merge_record = result.find { |r| r.entity == "file1.rb" }
        expect(merge_record.date).to eq(Date.parse("2023-01-10"))

        main_record = result.find { |r| r.entity == "file0.rb" }
        expect(main_record.date).to eq(Date.parse("2023-01-01"))
      end
    end

    context "with octopus merges" do
      let(:octopus_records) do
        [
          RubyMaat::ChangeRecord.new(
            entity: "file1.rb", author: "alice", date: "2023-01-10", revision: "octopus1",
            parent_revisions: %w[main1 feat_a1 feat_b1]
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file_a.rb", author: "bob", date: "2023-01-08", revision: "feat_a1",
            parent_revisions: %w[main1]
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file_b.rb", author: "charlie", date: "2023-01-09", revision: "feat_b1",
            parent_revisions: %w[main1]
          ),
          RubyMaat::ChangeRecord.new(
            entity: "file0.rb", author: "dave", date: "2023-01-01", revision: "main1",
            parent_revisions: %w[main0]
          )
        ]
      end

      it "handles octopus merges with multiple feature parents" do
        result = grouper.group(octopus_records)

        feat_a = result.find { |r| r.entity == "file_a.rb" }
        expect(feat_a.revision).to eq("octopus1")

        feat_b = result.find { |r| r.entity == "file_b.rb" }
        expect(feat_b.revision).to eq("octopus1")

        main_record = result.find { |r| r.entity == "file0.rb" }
        expect(main_record.revision).to eq("main1")
      end
    end

    it "skips grouping when mainline parent is not in the commit set" do
      records = [
        # Merge commit whose mainline parent is not in the log (filtered/truncated log)
        RubyMaat::ChangeRecord.new(
          entity: "file1.rb", author: "alice", date: "2023-01-05", revision: "merge1",
          parent_revisions: %w[missing_main feat1]
        ),
        RubyMaat::ChangeRecord.new(
          entity: "file2.rb", author: "bob", date: "2023-01-04", revision: "feat1",
          parent_revisions: %w[missing_main]
        )
      ]

      result = grouper.group(records)

      # Without a valid mainline parent, grouping should be skipped
      expect(result.map(&:revision)).to eq(%w[merge1 feat1])
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
