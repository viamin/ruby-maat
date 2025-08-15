# frozen_string_literal: true

require "date"

module RubyMaat
  # Main application orchestration
  # This is the Ruby equivalent of code-maat.app.app namespace
  class App
    SUPPORTED_VCS = %w[git git2 svn hg p4 tfs].freeze

    SUPPORTED_ANALYSES = {
      "authors" => RubyMaat::Analysis::Authors,
      "revisions" => RubyMaat::Analysis::Entities,
      "coupling" => RubyMaat::Analysis::LogicalCoupling,
      "soc" => RubyMaat::Analysis::SumOfCoupling,
      "summary" => RubyMaat::Analysis::Summary,
      "identity" => RubyMaat::Analysis::Identity,
      "abs-churn" => RubyMaat::Analysis::Churn::Absolute,
      "author-churn" => RubyMaat::Analysis::Churn::ByAuthor,
      "entity-churn" => RubyMaat::Analysis::Churn::ByEntity,
      "entity-ownership" => RubyMaat::Analysis::Churn::Ownership,
      "main-dev" => RubyMaat::Analysis::Churn::MainDeveloper,
      "refactoring-main-dev" => RubyMaat::Analysis::Churn::RefactoringMainDeveloper,
      "entity-effort" => RubyMaat::Analysis::Effort::ByRevisions,
      "main-dev-by-revs" => RubyMaat::Analysis::Effort::MainDeveloperByRevisions,
      "fragmentation" => RubyMaat::Analysis::Effort::Fragmentation,
      "communication" => RubyMaat::Analysis::Communication,
      "messages" => RubyMaat::Analysis::CommitMessages,
      "age" => RubyMaat::Analysis::CodeAge
    }.freeze

    def self.analysis_names
      SUPPORTED_ANALYSES.keys.sort.join(", ")
    end

    def initialize(options = {})
      @options = options
      validate_options!
    end

    def run
      # Parse VCS log file
      parser = create_parser
      change_records = parser.parse

      # Apply data transformations
      change_records = apply_grouping(change_records)
      change_records = apply_temporal_grouping(change_records)
      change_records = apply_team_mapping(change_records)

      # Convert to dataset
      dataset = Dataset.from_changes(change_records)

      # Run analysis
      analysis = create_analysis
      results = analysis.analyze(dataset, @options)

      # Output results
      output_handler = create_output_handler
      output_handler.write(results)
    rescue => e
      handle_error(e)
    end

    private

    def validate_options!
      raise ArgumentError, "Log file is required" unless @options[:log]
      raise ArgumentError, "Version control system is required" unless @options[:version_control]

      unless SUPPORTED_VCS.include?(@options[:version_control])
        raise ArgumentError, "Invalid VCS: #{@options[:version_control]}. Supported: #{SUPPORTED_VCS.join(", ")}"
      end

      return if SUPPORTED_ANALYSES.key?(@options[:analysis] || "authors")

      raise ArgumentError, "Invalid analysis: #{@options[:analysis]}. Supported: #{self.class.analysis_names}"
    end

    def create_parser
      case @options[:version_control]
      when "git"
        RubyMaat::Parsers::GitParser.new(@options[:log], @options)
      when "git2"
        RubyMaat::Parsers::Git2Parser.new(@options[:log], @options)
      when "svn"
        RubyMaat::Parsers::SvnParser.new(@options[:log], @options)
      when "hg"
        RubyMaat::Parsers::MercurialParser.new(@options[:log], @options)
      when "p4"
        RubyMaat::Parsers::PerforceParser.new(@options[:log], @options)
      when "tfs"
        RubyMaat::Parsers::TfsParser.new(@options[:log], @options)
      end
    end

    def apply_grouping(change_records)
      return change_records unless @options[:group]

      grouper = RubyMaat::Groupers::LayerGrouper.new(@options[:group])
      grouper.group(change_records)
    end

    def apply_temporal_grouping(change_records)
      return change_records unless @options[:temporal_period]

      grouper = RubyMaat::Groupers::TimeGrouper.new(@options[:temporal_period])
      grouper.group(change_records)
    end

    def apply_team_mapping(change_records)
      return change_records unless @options[:team_map_file]

      mapper = RubyMaat::Groupers::TeamMapper.new(@options[:team_map_file])
      mapper.map(change_records)
    end

    def create_analysis
      analysis_name = @options[:analysis] || "authors"
      analysis_class = SUPPORTED_ANALYSES[analysis_name]
      analysis_class.new
    end

    def create_output_handler
      if @options[:outfile]
        RubyMaat::Output::CsvOutput.new(@options[:outfile], @options[:rows])
      else
        RubyMaat::Output::CsvOutput.new(nil, @options[:rows]) # stdout
      end
    end

    def handle_error(error)
      case error
      when ArgumentError
        warn "Error: #{error.message}"
      else
        warn "Internal error: #{error.message}"
        warn error.backtrace.join("\n") if @options[:verbose]
      end
      exit 1
    end
  end
end
