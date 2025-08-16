# frozen_string_literal: true

require "spec_helper"
require "ruby_maat/generators/git_generator"
require "tmpdir"

RSpec.describe RubyMaat::Generators::GitGenerator do
  let(:temp_dir) { Dir.mktmpdir }
  let(:generator) { described_class.new(temp_dir) }

  before do
    # Create a mock git repository
    Dir.chdir(temp_dir) do
      `git init 2>/dev/null`
      `echo "test content" > test.txt`
      `git add test.txt 2>/dev/null`
      `git -c user.name="Test User" -c user.email="test@example.com" commit -m "Initial commit" 2>/dev/null`
    end
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#initialize" do
    it "initializes with a repository path" do
      expect(generator.repository_path).to eq(temp_dir)
    end

    it "raises error for non-git directory" do
      non_git_dir = Dir.mktmpdir
      expect { described_class.new(non_git_dir) }.to raise_error(ArgumentError, /Not a Git repository/)
      FileUtils.rm_rf(non_git_dir)
    end
  end

  describe "#available_presets" do
    it "returns available presets" do
      presets = generator.available_presets
      expect(presets).to be_a(Hash)
      expect(presets).to have_key("git2-format")
      expect(presets).to have_key("git-legacy")
      expect(presets).to have_key("recent-activity")
    end

    it "includes preset descriptions and options" do
      presets = generator.available_presets
      git2_preset = presets["git2-format"]

      expect(git2_preset).to have_key(:description)
      expect(git2_preset).to have_key(:options)
      expect(git2_preset[:options]).to include(format: "git2")
    end
  end

  describe "#generate_log" do
    context "when generating to stdout" do
      it "returns log output as string" do
        allow(generator).to receive(:execute_command).and_return("mocked log output")

        result = generator.generate_log
        expect(result).to eq("mocked log output")
      end
    end

    context "when generating to file" do
      let(:output_file) { File.join(temp_dir, "test.log") }

      it "creates log file" do
        allow(generator).to receive(:execute_command).and_return("mocked log output")

        generator.generate_log(output_file)

        expect(File.exist?(output_file)).to be true
        expect(File.read(output_file)).to eq("mocked log output")
      end
    end

    context "with git2 format" do
      it "builds correct git2 command" do
        expected_command = "git log --all --numstat --date=short --pretty=format:'--%h--%ad--%aN' --no-renames"
        allow(generator).to receive(:execute_command).with(expected_command)

        generator.generate_log(nil, format: "git2", all_branches: true, no_renames: true)
        expect(generator).to have_received(:execute_command).with(expected_command)
      end
    end

    context "with legacy format" do
      it "builds correct legacy command" do
        expected_command = "git log --all --pretty=format:'[%h] %aN %ad %s' --date=short --numstat --no-renames"
        allow(generator).to receive(:execute_command).with(expected_command)

        generator.generate_log(nil, format: "legacy", all_branches: true, no_renames: true)
        expect(generator).to have_received(:execute_command).with(expected_command)
      end
    end

    context "with date filtering" do
      it "includes date filters in command" do
        expected_command = "git log --all --numstat --date=short --pretty=format:'--%h--%ad--%aN' --no-renames --after=2023-01-01 --before=2023-12-31"
        allow(generator).to receive(:execute_command).with(expected_command)

        generator.generate_log(nil,
          format: "git2",
          all_branches: true,
          no_renames: true,
          since: "2023-01-01",
          until: "2023-12-31")
        expect(generator).to have_received(:execute_command).with(expected_command)
      end
    end
  end
end
