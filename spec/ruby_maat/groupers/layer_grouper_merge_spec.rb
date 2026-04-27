# frozen_string_literal: true

require "tempfile"

RSpec.describe RubyMaat::Groupers::LayerGrouper do
  describe "merge_commit preservation" do
    it "preserves merge_commit when mapping entities to layers" do
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

      grouping_file = Tempfile.new(["grouping", ".txt"])
      grouping_file.write("src/ => Backend\n")
      grouping_file.close

      grouper = described_class.new(grouping_file.path)
      grouped = grouper.group([merge_record, normal_record])

      expect(grouped[0].merge_commit).to be true
      expect(grouped[1].merge_commit).to be_nil

      grouping_file.unlink
    end
  end
end
