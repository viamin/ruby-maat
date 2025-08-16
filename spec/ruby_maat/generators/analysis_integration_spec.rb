# frozen_string_literal: true

require "spec_helper"
require "ruby_maat/generators/git_generator"
require "ruby_maat/analysis_presets"
require "tmpdir"

RSpec.describe RubyMaat::Generators::GitGenerator, "Analysis Integration" do
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

  describe "#interactive_generate_for_analysis" do
    before do
      allow($stdin).to receive(:tty?).and_return(true)
      # Mock all the interactive input methods to avoid hanging
      allow(generator).to receive_messages(execute_command: "--abc123--2023-01-01--Test User\n1\t0\ttest.rb\n", choose_analysis_preset: {since: "2023-01-01"}, gather_custom_options: {since: "2023-01-01"}, ask_yes_no: false, generate_log: "mock log")
    end

    it "uses analysis-specific presets for coupling analysis" do
      expect { generator.interactive_generate_for_analysis("coupling") }.not_to raise_error
      expect(generator).to have_received(:choose_analysis_preset).with("coupling", anything)
    end

    it "displays analysis description" do
      output = capture_stdout do
        generator.interactive_generate_for_analysis("coupling")
      end

      expect(output).to include("Logical Coupling Analysis")
      expect(output).to include("modules that change together")
    end

    it "shows analysis-specific presets" do
      # Test the preset selection directly instead of through interactive flow
      presets = RubyMaat::AnalysisPresets.presets_for_analysis("coupling")
      expect(presets).to have_key("recent-coupling")
      expect(presets["recent-coupling"][:description]).to include("Current coupling patterns")
    end

    it "handles analysis with no time filtering (age)" do
      output = capture_stdout do
        generator.interactive_generate_for_analysis("age")
      end

      expect(output).to include("Code Age Analysis")
    end

    it "uses appropriate preset options for analysis" do
      # Test that the interactive method uses analysis-specific presets
      allow(generator).to receive_messages(ask_yes_no: false, choose_analysis_preset: {since: "2023-01-01"}, gather_custom_options: {since: "2023-01-01"})

      allow(generator).to receive(:generate_log).with(
        nil, # No filename when not saving
        hash_including(since: "2023-01-01")
      ).and_return("mock log")

      # Call the method with all dependencies mocked
      capture_stdout do
        generator.interactive_generate_for_analysis("coupling")
      end

      expect(generator).to have_received(:generate_log).with(
        nil,
        hash_including(since: "2023-01-01")
      )
    end

    it "merges analysis-specific options" do
      analysis_options = {min_revs: 10, verbose: true}

      allow(generator).to receive(:generate_log).with(
        nil,
        hash_including(analysis_options)
      ).and_return("mock log")

      generator.interactive_generate_for_analysis("coupling", analysis_options)

      expect(generator).to have_received(:generate_log).with(
        nil,
        hash_including(analysis_options)
      )
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

  describe "#choose_analysis_preset" do
    let(:coupling_presets) { RubyMaat::AnalysisPresets.presets_for_analysis("coupling") }

    before do
      allow($stdin).to receive(:tty?).and_return(true)
      allow(generator).to receive(:ask_integer).and_return(1) # Always choose first option
    end

    it "displays presets with descriptions" do
      output = capture_stdout do
        generator.send(:choose_analysis_preset, "coupling", coupling_presets)
      end

      expect(output).to include("Available presets for coupling")
      expect(output).to include("recent-coupling")
      expect(output).to include("Current coupling patterns")
    end

    it "returns selected preset options" do
      result = generator.send(:choose_analysis_preset, "coupling", coupling_presets)

      expect(result).to be_a(Hash)
      expect(result[:description]).to include("Current coupling patterns")
      expect(result[:since]).to match(/\d{4}-\d{2}-\d{2}/)
    end

    it "returns empty hash for custom option" do
      preset_count = coupling_presets.length
      allow(generator).to receive(:ask_integer).and_return(preset_count + 1)

      result = generator.send(:choose_analysis_preset, "coupling", coupling_presets)

      expect(result).to eq({})
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

  describe "preset date generation" do
    it "generates dates within expected ranges for coupling analysis" do
      presets = RubyMaat::AnalysisPresets.presets_for_analysis("coupling")

      recent_date = Date.parse(presets["recent-coupling"][:since])
      trends_date = Date.parse(presets["coupling-trends"][:since])

      expect(recent_date).to be_within(2).of(Date.today - 90)  # ~3 months
      expect(trends_date).to be_within(2).of(Date.today - 365) # ~1 year
      expect(recent_date).to be > trends_date
    end

    it "does not include date filters for age analysis" do
      presets = RubyMaat::AnalysisPresets.presets_for_analysis("age")

      expect(presets["full-history"]).not_to have_key(:since)
      expect(presets["full-history"]).not_to have_key(:until)
    end
  end

  describe "error handling in analysis mode" do
    it "handles non-TTY gracefully" do
      allow($stdin).to receive(:tty?).and_return(false)

      expect { generator.interactive_generate_for_analysis("coupling") }
        .to raise_error(/Interactive mode requires a terminal/)
    end

    it "handles invalid analysis gracefully" do
      # Mock all interactive dependencies to avoid hanging
      allow($stdin).to receive(:tty?).and_return(true)
      allow(generator).to receive_messages(ask_yes_no: false, gather_custom_options: {}, generate_log: "mock log")

      # Should not crash, just show "No presets available"
      expect {
        generator.interactive_generate_for_analysis("nonexistent-analysis")
      }.to output(/No presets available/).to_stdout.and not_raise_error
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
