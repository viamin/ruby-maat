# frozen_string_literal: true

require "spec_helper"
require "ruby_maat/cli"
require "tmpdir"

RSpec.describe RubyMaat::CLI, "#log_generation" do
  let(:temp_dir) { Dir.mktmpdir }
  let(:cli) { described_class.new }
  let(:mock_generator) { instance_double(RubyMaat::Generators::GitGenerator) }
  let(:mock_app) { instance_double(RubyMaat::App) }

  before do
    # Mock all external dependencies completely to avoid directory and CLI execution issues
    allow(RubyMaat::Generators::GitGenerator).to receive(:new).and_return(mock_generator)
    allow(mock_generator).to receive_messages(generate_log: "mock log", available_presets: {
      "git2-format" => {options: {}}
    })
    allow(RubyMaat::App).to receive(:new).and_return(mock_app)
    allow(mock_app).to receive(:run)
    allow(RubyMaat::VcsDetector).to receive(:detect_vcs).and_return("git")
    # CRITICAL: Mock $stdin.tty? to return false to prevent actual interactive execution
    allow($stdin).to receive(:tty?).and_return(false)
  end

  after do
    FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exist?(temp_dir)
  end

  describe "CLI option parsing" do
    it "parses --generate-log option" do
      expect { cli.run(["--generate-log", "-c", "git"]) }.not_to raise_error
    end

    it "parses --save-log option" do
      allow(mock_generator).to receive(:generate_log).with("test.log").and_return("test.log")
      expect { cli.run(["--generate-log", "--save-log", "test.log", "-c", "git"]) }.not_to raise_error
    end

    it "parses --interactive option" do
      # This should raise TTY error (as SystemExit), not hang
      expect { cli.run(["--interactive", "--generate-log", "-c", "git"]) }.to raise_error(SystemExit)
    end

    it "parses --preset option" do
      expect { cli.run(["--preset", "git2-format", "--generate-log", "-c", "git"]) }.not_to raise_error
    end
  end

  describe "log generation mode" do
    it "does not require log file when generating logs" do
      expect { cli.run(["--generate-log", "-c", "git"]) }.not_to raise_error
    end

    it "still requires VCS type" do
      expect { cli.run(["--generate-log"]) }.to raise_error(SystemExit)
    end
  end

  describe "preset validation" do
    it "validates preset exists for VCS type" do
      expect { cli.run(["--preset", "invalid-preset", "--generate-log", "-c", "git"]) }
        .to raise_error(SystemExit)
    end
  end

  describe "unsupported VCS" do
    it "raises error for unsupported VCS in log generation" do
      expect { cli.run(["--generate-log", "-c", "hg"]) }
        .to raise_error(SystemExit)
    end
  end
end
