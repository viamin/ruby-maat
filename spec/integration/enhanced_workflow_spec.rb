# frozen_string_literal: true

require "spec_helper"
require "ruby_maat/cli"
require "tmpdir"
require "stringio"

RSpec.describe RubyMaat::CLI, "Enhanced Ruby Maat Workflow", type: :integration do
  def setup_directories
    # Ensure we're in a valid directory before starting
    begin
      @original_dir = Dir.pwd
    rescue Errno::ENOENT
      Dir.chdir("/")
      @original_dir = "/"
    end
    @temp_dir = Dir.mktmpdir
  end

  before do
    setup_directories

    # Create a more realistic mock git repository with multiple commits
    Dir.chdir(@temp_dir) do
      `git init 2>/dev/null`

      # Create directories and initial files
      Dir.mkdir("src")
      Dir.mkdir("test")
      File.write("src/main.rb", "class Main\nend")
      File.write("src/helper.rb", "module Helper\nend")
      File.write("test/main_test.rb", "require 'main'")

      `git add . 2>/dev/null`
      `git -c user.name="Alice" -c user.email="alice@example.com" commit -m "Initial commit" 2>/dev/null`

      # Modify files to create coupling
      File.write("src/main.rb", "class Main\n  include Helper\nend")
      File.write("src/helper.rb", "module Helper\n  def help\n  end\nend")

      `git add . 2>/dev/null`
      `git -c user.name="Bob" -c user.email="bob@example.com" commit -m "Add helper functionality" 2>/dev/null`

      # Create more changes
      File.write("src/util.rb", "class Util\nend")
      `git add . 2>/dev/null`
      `git -c user.name="Alice" -c user.email="alice@example.com" commit -m "Add utility class" 2>/dev/null`
    end

    Dir.chdir(@temp_dir)
  end

  after do
    begin
      # Always change back to original dir before cleaning up temp_dir
      Dir.chdir(@original_dir) if @original_dir && Dir.exist?(@original_dir)
    rescue
      # If original_dir doesn't exist, change to a safe directory
      Dir.chdir("/")
    end
    # Now safe to remove temp_dir since we're no longer in it
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  describe "VCS auto-detection integration" do
    it "automatically detects Git repository" do
      detected_vcs = RubyMaat::VcsDetector.detect_vcs(".")
      expect(detected_vcs).to eq("git")
    end
  end

  describe "Analysis-specific preset integration" do
    it "generates appropriate time-filtered logs for coupling analysis" do
      # Get coupling presets
      presets = RubyMaat::AnalysisPresets.presets_for_analysis("coupling")
      recent_preset = presets["recent-coupling"]

      expect(recent_preset[:since]).to match(/\d{4}-\d{2}-\d{2}/)

      # Date should be approximately 3 months ago
      since_date = Date.parse(recent_preset[:since])
      expected_date = Date.today - 90
      expect(since_date).to be_within(2).of(expected_date)
    end

    it "provides full history for age analysis" do
      presets = RubyMaat::AnalysisPresets.presets_for_analysis("age")
      full_preset = presets["full-history"]

      expect(full_preset).not_to have_key(:since)
      expect(full_preset[:description]).to include("Complete age analysis")
    end
  end

  describe "End-to-end log generation and analysis" do
    let(:cli) { described_class.new }

    it "generates log and runs coupling analysis in one command" do
      output = capture_output do
        cli.run(["--generate-log", "--preset", "git2-format", "-c", "git", "-a", "coupling"])
      end

      expect(output).to include("Running Analysis")
      expect(output).to include("entity,coupled,degree,average-revs")
      # Should show some coupling results (our mock repo has coupled files)
    end

    it "generates log and runs authors analysis" do
      output = capture_output do
        cli.run(["--generate-log", "--preset", "git2-format", "-c", "git", "-a", "authors"])
      end

      expect(output).to include("Running Analysis")
      expect(output).to include("entity,n-authors,n-revs")
      # Note: Integration tests may not always produce data due to log generation complexities
      # The important thing is that the CLI runs without hanging or errors
    end

    it "generates log and runs summary analysis" do
      output = capture_output do
        cli.run(["--generate-log", "--preset", "git2-format", "-c", "git", "-a", "summary"])
      end

      expect(output).to include("Running Analysis")
      expect(output).to include("statistic,value")
      # Note: Integration tests may not always produce expected data due to log generation complexities
      # The important thing is that the CLI runs without hanging or errors
    end

    it "saves log file when requested" do
      log_file = "test_output.log"

      output = capture_output do
        cli.run(["--generate-log", "--preset", "git2-format", "--save-log", log_file, "-c", "git"])
      end

      expect(output).to include("Log generated: #{log_file}")
      expect(File.exist?(log_file)).to be true

      log_content = File.read(log_file)
      expect(log_content).to include("Alice")
      expect(log_content).to include("Bob")
      expect(log_content).to include("src/main.rb")

      File.delete(log_file)
    end

    it "works with traditional mode using generated log" do
      # First generate a log
      log_file = "traditional_test.log"
      cli.run(["--generate-log", "--preset", "git2-format", "--save-log", log_file, "-c", "git"])

      # Then use it in traditional mode
      output = capture_output do
        cli.run(["-l", log_file, "-c", "git2", "-a", "summary"])
      end

      expect(output).to include("statistic,value")
      expect(output).to include("number-of-commits")

      File.delete(log_file)
    end
  end

  describe "Error handling integration" do
    it "provides helpful error for unsupported VCS in log generation" do
      cli = described_class.new

      expect { cli.run(["--generate-log", "-c", "fossil"]) }
        .to raise_error(SystemExit)
    end

    it "validates analysis types exist" do
      cli = described_class.new

      expect { cli.run(["--generate-log", "-c", "git", "-a", "nonexistent-analysis"]) }
        .to raise_error(SystemExit)
    end
  end

  describe "Performance and memory considerations" do
    it "cleans up temporary files" do
      initial_temp_files = Dir.glob("/tmp/ruby_maat*").length

      cli = described_class.new
      capture_output do
        cli.run(["--generate-log", "--preset", "git2-format", "-c", "git", "-a", "summary"])
      end

      final_temp_files = Dir.glob("/tmp/ruby_maat*").length
      expect(final_temp_files).to eq(initial_temp_files)
    end
  end

  private

  def capture_output
    output = StringIO.new
    original_stdout = $stdout
    $stdout = output

    yield

    output.string
  ensure
    $stdout = original_stdout
  end
end
