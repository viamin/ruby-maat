# frozen_string_literal: true

require "tempfile"

RSpec.describe RubyMaat::Groupers::TeamMapper do
  describe "merge_commit preservation" do
    it "preserves merge_commit when mapping authors to teams" do
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

      team_file = Tempfile.new(["teams", ".csv"])
      team_file.write("author,team\nAlice,Frontend\nBob,Backend\n")
      team_file.close

      mapper = described_class.new(team_file.path)
      mapped = mapper.map([merge_record, normal_record])

      expect(mapped[0].merge_commit).to be true
      expect(mapped[0].author).to eq("Frontend")
      expect(mapped[1].merge_commit).to be_nil

      team_file.unlink
    end
  end
end
