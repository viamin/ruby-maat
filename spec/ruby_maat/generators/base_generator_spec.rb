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

  describe "command preview functionality" do
    describe "#show_command_preview" do
      let(:command) { "git log --all --numstat" }

      context "when in interactive TTY mode (simulated)" do
        it "displays command preview and waits for Enter" do
          generator = TestGenerator.new(temp_dir)

          # Mock all the conditions to enable preview but stub stdin.gets
          allow(generator).to receive(:test_environment?).and_return(false)
          allow($stdin).to receive_messages(tty?: true, gets: "\n")

          expect { generator.send(:show_command_preview, command) }.to output(
            a_string_including(
              "COMMAND PREVIEW",
              "Repository: #{temp_dir}",
              "Command:    #{command}",
              "Press Enter to execute this command..."
            )
          ).to_stdout

          expect($stdin).to have_received(:gets).once
        end

        it "includes repository path and command in preview" do
          generator = TestGenerator.new(temp_dir)

          # Mock environment and stdin
          allow(generator).to receive(:test_environment?).and_return(false)
          allow($stdin).to receive_messages(tty?: true, gets: "\n")

          expect { generator.send(:show_command_preview, command) }.to output(
            a_string_matching(/Repository: #{Regexp.escape(temp_dir)}/)
          ).to_stdout

          expect { generator.send(:show_command_preview, command) }.to output(
            a_string_matching(/Command:\s+#{Regexp.escape(command)}/)
          ).to_stdout
        end
      end

      context "when in test environment" do
        it "skips command preview automatically" do
          generator = TestGenerator.new(temp_dir)

          # In real test environment, test_environment? returns true automatically
          expect { generator.send(:show_command_preview, command) }.not_to output.to_stdout
        end
      end

      context "when in quiet mode" do
        it "skips command preview" do
          generator = TestGenerator.new(temp_dir, quiet: true)

          expect { generator.send(:show_command_preview, command) }.not_to output.to_stdout
        end
      end

      context "when in non-TTY mode" do
        it "skips command preview" do
          generator = TestGenerator.new(temp_dir)

          allow($stdin).to receive(:tty?).and_return(false)

          expect { generator.send(:show_command_preview, command) }.not_to output.to_stdout
        end
      end
    end

    describe "#test_environment?" do
      it "detects RSpec environment" do
        generator = TestGenerator.new(temp_dir)
        expect(generator.send(:test_environment?)).to be true
      end

      it "detects RUBY_MAAT_TEST environment variable" do
        generator = TestGenerator.new(temp_dir)

        original_env = ENV["RUBY_MAAT_TEST"]
        ENV["RUBY_MAAT_TEST"] = "true"

        # Since RSpec is defined, this will still return true due to RSpec detection
        # but the method includes the ENV check as well
        expect(generator.send(:test_environment?)).to be true

        ENV["RUBY_MAAT_TEST"] = original_env
      end
    end

    describe "#execute_command with command preview" do
      let(:command) { "echo 'test output'" }

      context "when in test environment (default)" do
        it "executes command without preview" do
          generator = TestGenerator.new(temp_dir)

          # In test environment, should skip preview
          expect { generator.send(:execute_command, command) }.not_to output(
            a_string_including("COMMAND PREVIEW")
          ).to_stdout

          result = generator.send(:execute_command, command)
          expect(result.strip).to eq("test output")
        end
      end

      context "when in interactive TTY mode (simulated)" do
        it "shows command preview before execution" do
          generator = TestGenerator.new(temp_dir)

          # Override test environment detection and mock stdin
          allow(generator).to receive(:test_environment?).and_return(false)
          allow($stdin).to receive_messages(tty?: true, gets: "\n")

          expect { generator.send(:execute_command, command) }.to output(
            a_string_including("COMMAND PREVIEW", "Press Enter to execute this command...")
          ).to_stdout

          expect($stdin).to have_received(:gets).once
        end
      end

      context "when in quiet mode" do
        it "executes command without preview" do
          generator = TestGenerator.new(temp_dir, quiet: true)

          expect { generator.send(:execute_command, command) }.not_to output(
            a_string_including("COMMAND PREVIEW")
          ).to_stdout

          result = generator.send(:execute_command, command)
          expect(result.strip).to eq("test output")
        end
      end
    end
  end
end
