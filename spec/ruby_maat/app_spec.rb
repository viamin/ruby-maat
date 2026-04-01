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
  end
end
