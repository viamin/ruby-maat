# frozen_string_literal: true

RSpec.describe RubyMaat::Groupers::TimeGrouper do
  describe "merge_commit preservation" do
    it "preserves merge_commit when aggregating by time period" do
      merge_record = RubyMaat::ChangeRecord.new(
        entity: "src/main.rb", author: "Alice", date: "2023-01-15",
        revision: "abc123", message: "Merge pull request #42",
        loc_added: 10, loc_deleted: 5, merge_commit: true
      )
      normal_record = RubyMaat::ChangeRecord.new(
        entity: "src/helper.rb", author: "Bob", date: "2023-01-15",
        revision: "def456", message: "Add helper",
        loc_added: 20, loc_deleted: 0, merge_commit: nil
      )

      grouper = described_class.new("day")
      grouped = grouper.group([merge_record, normal_record])

      merge_grouped = grouped.find { |r| r.entity == "src/main.rb" }
      normal_grouped = grouped.find { |r| r.entity == "src/helper.rb" }

      expect(merge_grouped.merge_commit).to be true
      expect(normal_grouped.merge_commit).to be_nil
    end

    it "marks time-grouped record as merge if any constituent is a merge" do
      merge_variant = RubyMaat::ChangeRecord.new(
        entity: "src/main.rb", author: "Alice", date: "2023-01-15",
        revision: "abc123", message: "Merge pull request #42",
        loc_added: 10, loc_deleted: 5, merge_commit: true
      )
      normal_variant = RubyMaat::ChangeRecord.new(
        entity: "src/main.rb", author: "Alice", date: "2023-01-15",
        revision: "def456", message: "Regular commit",
        loc_added: 3, loc_deleted: 1, merge_commit: nil
      )

      grouper = described_class.new("day")
      grouped = grouper.group([merge_variant, normal_variant])

      expect(grouped.length).to eq(1)
      expect(grouped[0].merge_commit).to be true
    end
  end
end
