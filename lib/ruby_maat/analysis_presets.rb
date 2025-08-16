# frozen_string_literal: true

require "date"

module RubyMaat
  module AnalysisPresets
    # Analysis configurations with appropriate time ranges and descriptions
    ANALYSIS_CONFIGS = {
      "authors" => {
        name: "Developer Activity Analysis",
        description: "Shows number of developers working on each module",
        time_sensitive: true,
        presets: {
          "team-activity" => {
            description: "Team activity patterns (6 months)",
            since: -> { (Date.today - 180).strftime("%Y-%m-%d") }
          },
          "recent-team" => {
            description: "Recent team changes (3 months)",
            since: -> { (Date.today - 90).strftime("%Y-%m-%d") }
          },
          "team-history" => {
            description: "Complete team evolution (2 years)",
            since: -> { (Date.today - 730).strftime("%Y-%m-%d") }
          }
        }
      },

      "coupling" => {
        name: "Logical Coupling Analysis",
        description: "Finds modules that change together (hidden dependencies)",
        time_sensitive: true,
        presets: {
          "recent-coupling" => {
            description: "Current coupling patterns (3 months)",
            since: -> { (Date.today - 90).strftime("%Y-%m-%d") }
          },
          "coupling-trends" => {
            description: "Coupling evolution (1 year)",
            since: -> { (Date.today - 365).strftime("%Y-%m-%d") }
          },
          "architecture-review" => {
            description: "Deep architecture analysis (6 months)",
            since: -> { (Date.today - 180).strftime("%Y-%m-%d") }
          }
        }
      },

      "age" => {
        name: "Code Age Analysis",
        description: "Shows how recently each module was modified",
        time_sensitive: false,
        presets: {
          "full-history" => {
            description: "Complete age analysis (all history)"
          }
        }
      },

      "abs-churn" => {
        name: "Absolute Code Churn",
        description: "Total lines added/deleted over time",
        time_sensitive: true,
        presets: {
          "recent-churn" => {
            description: "Recent development activity (6 months)",
            since: -> { (Date.today - 180).strftime("%Y-%m-%d") }
          },
          "yearly-churn" => {
            description: "Annual churn patterns (1 year)",
            since: -> { (Date.today - 365).strftime("%Y-%m-%d") }
          },
          "project-churn" => {
            description: "Project lifecycle churn (2 years)",
            since: -> { (Date.today - 730).strftime("%Y-%m-%d") }
          }
        }
      },

      "author-churn" => {
        name: "Author Churn Analysis",
        description: "Code churn by individual developers",
        time_sensitive: true,
        presets: {
          "contributor-activity" => {
            description: "Current contributor patterns (6 months)",
            since: -> { (Date.today - 180).strftime("%Y-%m-%d") }
          },
          "team-contributions" => {
            description: "Team contribution history (1 year)",
            since: -> { (Date.today - 365).strftime("%Y-%m-%d") }
          }
        }
      },

      "entity-churn" => {
        name: "Module Churn Analysis",
        description: "Churn by individual modules/files",
        time_sensitive: true,
        presets: {
          "hotspot-analysis" => {
            description: "Current hotspots (6 months)",
            since: -> { (Date.today - 180).strftime("%Y-%m-%d") }
          },
          "stability-review" => {
            description: "Module stability patterns (1 year)",
            since: -> { (Date.today - 365).strftime("%Y-%m-%d") }
          }
        }
      },

      "entity-ownership" => {
        name: "Code Ownership Analysis",
        description: "Shows ownership distribution of code",
        time_sensitive: true,
        presets: {
          "current-ownership" => {
            description: "Current ownership patterns (1 year)",
            since: -> { (Date.today - 365).strftime("%Y-%m-%d") }
          },
          "ownership-evolution" => {
            description: "Ownership changes over time (2 years)",
            since: -> { (Date.today - 730).strftime("%Y-%m-%d") }
          }
        }
      },

      "main-dev" => {
        name: "Main Developer Analysis",
        description: "Identifies primary developer for each module",
        time_sensitive: true,
        presets: {
          "current-maintainers" => {
            description: "Current module maintainers (1 year)",
            since: -> { (Date.today - 365).strftime("%Y-%m-%d") }
          },
          "maintainer-history" => {
            description: "Maintainer evolution (2 years)",
            since: -> { (Date.today - 730).strftime("%Y-%m-%d") }
          }
        }
      },

      "entity-effort" => {
        name: "Development Effort Analysis",
        description: "Effort distribution across modules",
        time_sensitive: true,
        presets: {
          "effort-focus" => {
            description: "Recent effort distribution (6 months)",
            since: -> { (Date.today - 180).strftime("%Y-%m-%d") }
          },
          "effort-trends" => {
            description: "Effort patterns over time (1 year)",
            since: -> { (Date.today - 365).strftime("%Y-%m-%d") }
          }
        }
      },

      "communication" => {
        name: "Team Communication Analysis",
        description: "Developer collaboration patterns",
        time_sensitive: true,
        presets: {
          "team-collaboration" => {
            description: "Current collaboration patterns (6 months)",
            since: -> { (Date.today - 180).strftime("%Y-%m-%d") }
          },
          "communication-trends" => {
            description: "Communication evolution (1 year)",
            since: -> { (Date.today - 365).strftime("%Y-%m-%d") }
          }
        }
      },

      "summary" => {
        name: "Project Summary",
        description: "High-level project statistics",
        time_sensitive: true,
        presets: {
          "project-overview" => {
            description: "Current project state (1 year)",
            since: -> { (Date.today - 365).strftime("%Y-%m-%d") }
          },
          "full-summary" => {
            description: "Complete project history"
          }
        }
      },

      "revisions" => {
        name: "Revision Count Analysis",
        description: "Number of changes per module",
        time_sensitive: true,
        presets: {
          "activity-hotspots" => {
            description: "Current activity patterns (6 months)",
            since: -> { (Date.today - 180).strftime("%Y-%m-%d") }
          },
          "change-history" => {
            description: "Complete change patterns (2 years)",
            since: -> { (Date.today - 730).strftime("%Y-%m-%d") }
          }
        }
      },

      # Analyses that don't benefit from time filtering
      "identity" => {
        name: "Identity Analysis",
        description: "Raw parsed data (debugging/export)",
        time_sensitive: false,
        presets: {
          "full-data" => {
            description: "Complete dataset export"
          }
        }
      },

      "soc" => {
        name: "Sum of Coupling",
        description: "Total coupling strength per module",
        time_sensitive: true,
        presets: {
          "coupling-strength" => {
            description: "Current coupling analysis (6 months)",
            since: -> { (Date.today - 180).strftime("%Y-%m-%d") }
          }
        }
      },

      "refactoring-main-dev" => {
        name: "Refactoring Main Developer",
        description: "Main developer in refactoring contexts",
        time_sensitive: true,
        presets: {
          "refactoring-leads" => {
            description: "Recent refactoring activity (1 year)",
            since: -> { (Date.today - 365).strftime("%Y-%m-%d") }
          }
        }
      },

      "main-dev-by-revs" => {
        name: "Main Developer (by Revisions)",
        description: "Main developer by revision count",
        time_sensitive: true,
        presets: {
          "revision-leaders" => {
            description: "Current revision leaders (1 year)",
            since: -> { (Date.today - 365).strftime("%Y-%m-%d") }
          }
        }
      },

      "fragmentation" => {
        name: "Development Fragmentation",
        description: "How fragmented development effort is",
        time_sensitive: true,
        presets: {
          "team-fragmentation" => {
            description: "Current team fragmentation (6 months)",
            since: -> { (Date.today - 180).strftime("%Y-%m-%d") }
          }
        }
      },

      "messages" => {
        name: "Commit Message Analysis",
        description: "Analyzes commit message patterns",
        time_sensitive: true,
        presets: {
          "message-patterns" => {
            description: "Recent commit patterns (6 months)",
            since: -> { (Date.today - 180).strftime("%Y-%m-%d") }
          },
          "communication-style" => {
            description: "Team communication style (1 year)",
            since: -> { (Date.today - 365).strftime("%Y-%m-%d") }
          }
        }
      }
    }.freeze

    def self.analysis_config(analysis_name)
      ANALYSIS_CONFIGS[analysis_name]
    end

    def self.available_analyses
      ANALYSIS_CONFIGS.keys.sort
    end

    def self.analysis_description(analysis_name)
      config = ANALYSIS_CONFIGS[analysis_name]
      return "Unknown analysis" unless config
      "#{config[:name]} - #{config[:description]}"
    end

    def self.presets_for_analysis(analysis_name)
      config = ANALYSIS_CONFIGS[analysis_name]
      return {} unless config

      # Evaluate lambda functions in preset options
      config[:presets].transform_values do |preset|
        preset.transform_values { |v| v.is_a?(Proc) ? v.call : v }
      end
    end

    def self.time_sensitive?(analysis_name)
      config = ANALYSIS_CONFIGS[analysis_name]
      config ? config[:time_sensitive] : false
    end
  end
end
