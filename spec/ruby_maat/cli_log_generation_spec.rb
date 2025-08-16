# frozen_string_literal: true

require "spec_helper"
require "ruby_maat/cli"
require "tmpdir"

RSpec.describe RubyMaat::CLI, "log generation" do
  let(:temp_dir) { Dir.mktmpdir }
  let(:cli) { described_class.new }

  before do
    # Create a mock git repository
    Dir.chdir(temp_dir) do
      `git init 2>/dev/null`
      `echo "test content" > test.txt`
      `git add test.txt 2>/dev/null`
      `git -c user.name="Test User" -c user.email="test@example.com" commit -m "Initial commit" 2>/dev/null`
    end

    # Change to temp directory for tests
    @original_dir = Dir.pwd
    Dir.chdir(temp_dir)
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(temp_dir)
  end

  describe "CLI option parsing" do
    it "parses --generate-log option" do
      expect { cli.run(["--generate-log", "-c", "git"]) }.not_to raise_error
    end

    it "parses --save-log option" do
      expect { cli.run(["--save-log", "test.log", "-c", "git"]) }.not_to raise_error
    end

    it "parses --interactive option" do
      expect { cli.run(["--interactive", "--generate-log", "-c", "git"]) }.not_to raise_error
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
      expect { cli.run(["--generate-log"]) }.to raise_error(ArgumentError, /version control system/)
    end
  end

  describe "preset validation" do
    it "validates preset exists for VCS type" do
      expect { cli.run(["--preset", "invalid-preset", "--generate-log", "-c", "git"]) }
        .to raise_error(ArgumentError, /Unknown preset/)
    end
  end

  describe "unsupported VCS" do
    it "raises error for unsupported VCS in log generation" do
      expect { cli.run(["--generate-log", "-c", "hg"]) }
        .to raise_error(ArgumentError, /Log generation not yet supported/)
    end
  end
end
