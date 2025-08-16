# frozen_string_literal: true

require "spec_helper"
require "ruby_maat/analysis_presets"

RSpec.describe RubyMaat::AnalysisPresets do
  describe ".analysis_config" do
    it "returns config for valid analysis" do
      config = described_class.analysis_config("coupling")
      expect(config).to be_a(Hash)
      expect(config[:name]).to eq("Logical Coupling Analysis")
      expect(config[:description]).to include("modules that change together")
    end

    it "returns nil for invalid analysis" do
      expect(described_class.analysis_config("invalid")).to be_nil
    end
  end

  describe ".available_analyses" do
    it "returns sorted list of analysis names" do
      analyses = described_class.available_analyses
      expect(analyses).to be_an(Array)
      expect(analyses).to include("coupling", "authors", "age", "summary")
      expect(analyses).to eq(analyses.sort)
    end
  end

  describe ".analysis_description" do
    it "returns formatted description for valid analysis" do
      desc = described_class.analysis_description("coupling")
      expect(desc).to eq("Logical Coupling Analysis - Finds modules that change together (hidden dependencies)")
    end

    it "returns unknown for invalid analysis" do
      desc = described_class.analysis_description("invalid")
      expect(desc).to eq("Unknown analysis")
    end
  end

  describe ".presets_for_analysis" do
    context "with time-sensitive analysis" do
      it "returns presets with evaluated dates for coupling" do
        presets = described_class.presets_for_analysis("coupling")

        expect(presets).to have_key("recent-coupling")
        expect(presets).to have_key("coupling-trends")

        recent = presets["recent-coupling"]
        expect(recent[:description]).to include("3 months")
        expect(recent[:since]).to match(/\d{4}-\d{2}-\d{2}/)

        # Verify date is approximately 3 months ago
        since_date = Date.parse(recent[:since])
        expected_date = Date.today - 90
        expect(since_date).to be_within(1).of(expected_date)
      end

      it "returns presets for authors analysis" do
        presets = described_class.presets_for_analysis("authors")

        expect(presets).to have_key("team-activity")
        expect(presets).to have_key("recent-team")
        expect(presets).to have_key("team-history")

        team_activity = presets["team-activity"]
        expect(team_activity[:description]).to include("6 months")
        expect(team_activity[:since]).to match(/\d{4}-\d{2}-\d{2}/)
      end
    end

    context "with time-insensitive analysis" do
      it "returns presets without date filters for age analysis" do
        presets = described_class.presets_for_analysis("age")

        expect(presets).to have_key("full-history")

        full_history = presets["full-history"]
        expect(full_history[:description]).to include("Complete age analysis")
        expect(full_history).not_to have_key(:since)
      end

      it "returns presets for identity analysis" do
        presets = described_class.presets_for_analysis("identity")

        expect(presets).to have_key("full-data")
        expect(presets["full-data"]).not_to have_key(:since)
      end
    end

    it "returns empty hash for invalid analysis" do
      presets = described_class.presets_for_analysis("invalid")
      expect(presets).to eq({})
    end
  end

  describe ".time_sensitive?" do
    it "returns true for time-sensitive analyses" do
      expect(described_class.time_sensitive?("coupling")).to be true
      expect(described_class.time_sensitive?("authors")).to be true
      expect(described_class.time_sensitive?("abs-churn")).to be true
    end

    it "returns false for time-insensitive analyses" do
      expect(described_class.time_sensitive?("age")).to be false
      expect(described_class.time_sensitive?("identity")).to be false
    end

    it "returns false for invalid analysis" do
      expect(described_class.time_sensitive?("invalid")).to be false
    end
  end

  describe "date calculations" do
    it "generates dates within reasonable ranges" do
      presets = described_class.presets_for_analysis("coupling")

      recent_date = Date.parse(presets["recent-coupling"][:since])
      trends_date = Date.parse(presets["coupling-trends"][:since])

      expect(recent_date).to be > trends_date # Recent should be more recent than trends
      expect(trends_date).to be > (Date.today - 400) # Within reasonable bounds
    end
  end

  describe "preset consistency" do
    it "ensures all analyses have at least one preset" do
      described_class.available_analyses.each do |analysis|
        presets = described_class.presets_for_analysis(analysis)
        expect(presets).not_to be_empty, "Analysis '#{analysis}' should have at least one preset"
      end
    end

    it "ensures all preset descriptions are meaningful" do
      described_class.available_analyses.each do |analysis|
        presets = described_class.presets_for_analysis(analysis)
        presets.each do |name, config|
          expect(config[:description]).to be_a(String)
          expect(config[:description].length).to be > 10, "Preset '#{name}' for '#{analysis}' should have meaningful description"
        end
      end
    end
  end
end
