# frozen_string_literal: true

require "spec_helper"
require "ruby_maat/cli"
require "tmpdir"
require "stringio"

RSpec.describe RubyMaat::CLI do
  let(:cli) { described_class.new }
  let(:mock_generator) { instance_double(RubyMaat::Generators::GitGenerator) }
  let(:mock_app) { instance_double(RubyMaat::App) }

  attr_reader :temp_dir

  before do
    @temp_dir = Dir.mktmpdir
    @original_dir = Dir.pwd

    # Mock all external dependencies completely to avoid directory issues
    allow(RubyMaat::Generators::GitGenerator).to receive(:new).and_return(mock_generator)
    allow(mock_generator).to receive_messages(generate_log: "mock log", interactive_generate_for_analysis: "mock log", available_presets: {
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

  describe "validation with interactive mode" do
    it "allows --interactive without any other options" do
      # Should not raise validation errors, only TTY error that results in SystemExit
      expect { cli.run(["--interactive"]) }.to raise_error(SystemExit)
    end

    it "allows --interactive with analysis pre-specified" do
      expect { cli.run(["--interactive", "-a", "coupling"]) }.to raise_error(SystemExit)
    end

    it "allows --interactive with VCS pre-specified" do
      expect { cli.run(["--interactive", "-c", "git"]) }.to raise_error(SystemExit)
    end

    it "allows --interactive with both analysis and VCS pre-specified" do
      expect { cli.run(["--interactive", "-c", "git", "-a", "coupling"]) }.to raise_error(SystemExit)
    end

    it "validates required options correctly in interactive mode" do
      # Test validation logic without actually running interactive mode
      cli_instance = described_class.new

      # Set interactive option and validate
      cli_instance.instance_variable_set(:@options, {interactive: true})
      expect { cli_instance.send(:validate_required_options!) }.not_to raise_error

      # Test non-interactive still requires options
      cli_instance.instance_variable_set(:@options, {})
      expect { cli_instance.send(:validate_required_options!) }.to raise_error(ArgumentError, /log file/)
    end
  end

  describe "log generation with analysis execution" do
    let(:mock_log_output) { "--abc123--2023-01-01--Test User\n1\t0\ttest.txt\n" }

    before do
      # Mock generator creation and execution
      allow(RubyMaat::Generators::GitGenerator).to receive(:new).and_return(mock_generator)
      allow(mock_generator).to receive_messages(generate_log: mock_log_output, available_presets: {
        "git2-format" => {options: {}}
      })
      allow(RubyMaat::App).to receive(:new).and_return(mock_app)
      allow(mock_app).to receive(:run)
    end

    it "runs analysis after generating log when no save-log specified" do
      output = capture_stdout do
        cli.run(["--generate-log", "--preset", "git2-format", "-c", "git", "-a", "summary"])
      end

      expect(output).to include("Running Analysis")
      expect(mock_generator).to have_received(:generate_log)
      expect(mock_app).to have_received(:run)
    end

    it "saves log file when save-log is specified" do
      log_file = File.join(temp_dir, "test.log")

      # Mock generator to return the filename when called with save-log
      allow(mock_generator).to receive(:generate_log).with(log_file).and_return(log_file)

      output = capture_stdout do
        cli.run(["--generate-log", "--preset", "git2-format", "--save-log", log_file, "-c", "git"])
      end

      expect(output).to include("Log generated: #{log_file}")
      expect(mock_generator).to have_received(:generate_log).with(log_file)
    end

    it "runs analysis on saved log file when save-log is specified and analysis is not default" do
      log_file = File.join(temp_dir, "test.log")

      # Mock file writing
      allow(File).to receive(:write).with(log_file, mock_log_output)

      output = capture_stdout do
        cli.run(["--generate-log", "--preset", "git2-format", "--save-log", log_file, "-c", "git", "-a", "coupling"])
      end

      expect(output).to include("Log generated: #{log_file}")
      expect(output).to include("Running Analysis")
      expect(mock_app).to have_received(:run)
    end
  end

  describe "preset handling" do
    let(:preset_generator) { instance_double(RubyMaat::Generators::GitGenerator) }

    before do
      allow(RubyMaat::Generators::GitGenerator).to receive(:new).and_return(preset_generator)
      allow(preset_generator).to receive(:available_presets).and_return({
        "git2-format" => {options: {}}
      })
    end

    it "validates preset exists for specified VCS" do
      expect { cli.run(["--generate-log", "--preset", "nonexistent-preset", "-c", "git"]) }
        .to raise_error(SystemExit)
    end

    it "accepts valid presets for Git" do
      allow(preset_generator).to receive(:generate_log).and_return("mock log")

      expect { cli.run(["--generate-log", "--preset", "git2-format", "-c", "git"]) }
        .not_to raise_error
    end
  end

  describe "error handling" do
    it "provides helpful error for non-TTY interactive mode" do
      # Explicitly mock $stdin.tty? to return false for this test
      allow($stdin).to receive(:tty?).and_return(false)
      expect { cli.run(["--interactive"]) }.to raise_error(SystemExit)
    end

    it "handles missing VCS for log generation" do
      expect { cli.run(["--generate-log", "--preset", "git2-format"]) }.to raise_error(SystemExit)
    end

    it "handles unsupported VCS for log generation" do
      expect { cli.run(["--generate-log", "-c", "bazaar"]) }.to raise_error(SystemExit)
    end
  end

  describe "traditional mode compatibility" do
    let(:log_file) { File.join(temp_dir, "existing.log") }

    before do
      # Create a simple log file
      File.write(log_file, "--abc123--2023-01-01--Test User\n1\t0\ttest.rb\n")
      allow(RubyMaat::App).to receive(:new).and_return(mock_app)
      allow(mock_app).to receive(:run)
    end

    it "still requires log file in traditional mode" do
      expect { cli.run(["-c", "git2", "-a", "summary"]) }.to raise_error(SystemExit)
    end

    it "works with existing log files" do
      expect { cli.run(["-l", log_file, "-c", "git2", "-a", "summary"]) }
        .not_to raise_error

      expect(mock_app).to have_received(:run)
    end
  end

  private

  def capture_stdout
    output = StringIO.new
    original_stdout = $stdout
    $stdout = output

    yield

    output.string
  ensure
    $stdout = original_stdout
  end
end
