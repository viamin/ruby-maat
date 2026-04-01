# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyMaat::App do
  describe "#run with --group-by-merge" do
    let(:log_file) { File.join(__dir__, "../fixtures/code_maat/end_to_end/simple_git2.txt") }

    it "raises an error when log lacks parent revision metadata" do
      app = described_class.new(
        log: log_file,
        version_control: "git2",
        analysis: "coupling",
        group_by_merge: true
      )

      expect { app.run }.to raise_error(SystemExit).and output(/group-by-merge requires parent revision metadata/).to_stderr
    end

    it "does not raise when log yields empty change records" do
      allow(RubyMaat::Parsers::Git2Parser).to receive(:new).and_return(
        instance_double(RubyMaat::Parsers::Git2Parser, parse: [])
      )

      app = described_class.new(
        log: log_file,
        version_control: "git2",
        analysis: "revisions",
        group_by_merge: true
      )

      expect { app.run }.not_to raise_error
    end

    it "does not raise when log has parent metadata but only root commits (empty parent lists)" do
      # Root commits legitimately have parent_revisions == [] when parsed with the parents format.
      # The validation should detect that parent metadata is present (non-nil) and not error.
      allow(RubyMaat::Parsers::Git2Parser).to receive(:new).and_return(
        instance_double(RubyMaat::Parsers::Git2Parser, parse: [
          RubyMaat::ChangeRecord.new(
            entity: "file.rb", author: "dev", date: "2024-01-01",
            revision: "abc123", parent_revisions: []
          )
        ])
      )

      app = described_class.new(
        log: log_file,
        version_control: "git2",
        analysis: "revisions",
        group_by_merge: true
      )

      expect { app.run }.not_to raise_error
    end
  end
end
