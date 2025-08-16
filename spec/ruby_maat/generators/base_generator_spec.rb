# frozen_string_literal: true

require "spec_helper"
require "ruby_maat/generators/base_generator"
require "tmpdir"

# Test implementation of BaseGenerator for testing
class TestGenerator < RubyMaat::Generators::BaseGenerator
  def available_presets
    {
      "test-preset" => {
        description: "Test preset",
        options: {test_option: "test_value"}
      }
    }
  end

  protected

  def build_command(options)
    "test command with #{options[:test_option] || "default"}"
  end
end

RSpec.describe RubyMaat::Generators::BaseGenerator do
  let(:temp_dir) { Dir.mktmpdir }
  let(:generator) { TestGenerator.new(temp_dir) }

  before do
    FileUtils.mkdir_p(temp_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#initialize" do
    it "initializes with repository path and options" do
      opts = {verbose: true}
      gen = TestGenerator.new(temp_dir, opts)

      expect(gen.repository_path).to eq(temp_dir)
      expect(gen.options).to eq(opts)
    end

    it "expands repository path" do
      relative_path = "."
      gen = TestGenerator.new(relative_path)
      expect(gen.repository_path).to eq(File.expand_path(relative_path))
    end

    it "raises error for non-existent directory" do
      non_existent = "/path/that/does/not/exist"
      expect { TestGenerator.new(non_existent) }.to raise_error(ArgumentError, /does not exist/)
    end
  end

  describe "#generate_log" do
    context "without output file" do
      it "generates temporary log" do
        allow(generator).to receive(:execute_command).with("test command with default").and_return("log output")

        result = generator.generate_log
        expect(result).to eq("log output")
        expect(generator).to have_received(:execute_command).with("test command with default")
      end
    end

    context "with output file" do
      let(:output_file) { File.join(temp_dir, "test.log") }

      it "generates persistent log file" do
        allow(generator).to receive(:execute_command).with("test command with default").and_return("log output")

        result = generator.generate_log(output_file)

        expect(result).to eq(output_file)
        expect(File.exist?(output_file)).to be true
        expect(File.read(output_file)).to eq("log output")
        expect(generator).to have_received(:execute_command).with("test command with default")
      end
    end

    context "with options" do
      it "merges options and passes to build_command" do
        allow(generator).to receive(:execute_command).with("test command with custom").and_return("log output")

        generator.generate_log(nil, test_option: "custom")
        expect(generator).to have_received(:execute_command).with("test command with custom")
      end
    end
  end

  describe "#default_log_filename" do
    it "generates filename with timestamp" do
      filename = generator.send(:default_log_filename)
      expect(filename).to match(/^test_log_\d{8}_\d{6}\.log$/)
    end
  end

  describe "#vcs_name" do
    it "extracts VCS name from class name" do
      expect(generator.send(:vcs_name)).to eq("test")
    end
  end

  describe "command execution" do
    describe "#execute_command" do
      let(:generator) { TestGenerator.new(temp_dir, verbose: true) }

      it "executes command in repository directory" do
        # Create a test file to verify we're in the right directory
        test_file = File.join(temp_dir, "marker.txt")
        File.write(test_file, "test")

        result = generator.send(:execute_command, "ls marker.txt")
        expect(result.strip).to eq("marker.txt")
      end

      it "raises error for failed commands" do
        expect { generator.send(:execute_command, "false") }.to raise_error(RuntimeError, /Command failed/)
      end
    end
  end
end
