# frozen_string_literal: true

require "optparse"
require "date"

module RubyMaat
  # Command Line Interface - Ruby port of code-maat.cmd-line
  class CLI
    VERSION_INFO = "Ruby Maat version #{RubyMaat::VERSION} - A Ruby port of Code Maat".freeze

    def initialize
      @options = {}
      @parser = build_option_parser
    end

    def run(args)
      @parser.parse!(args)

      if @options[:help]
        puts usage
        exit 0
      end

      validate_required_options!

      app = App.new(@options)
      app.run
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      warn "Error: #{e.message}"
      warn usage
      exit 1
    rescue ArgumentError => e
      warn "Error: #{e.message}"
      warn usage
      exit 1
    rescue => e
      warn "Error: #{e.message}"
      warn e.backtrace.join("\n") if @options[:verbose]
      exit 1
    end

    private

    def build_option_parser
      OptionParser.new do |opts|
        opts.banner = usage_banner

        # Required options
        opts.on("-l", "--log LOG", "Log file with input data") do |log|
          @options[:log] = log
        end

        opts.on("-c", "--version-control VCS",
          "Input vcs module type: supports svn, git, git2, hg, p4, or tfs") do |vcs|
          @options[:version_control] = vcs
        end

        # Analysis selection
        opts.on("-a", "--analysis ANALYSIS",
          "The analysis to run (#{App.analysis_names})",
          "(default: authors)") do |analysis|
          @options[:analysis] = analysis
        end

        # Input/Output options
        opts.on("--input-encoding ENCODING",
          "Specify an encoding other than UTF-8 for the log file") do |encoding|
          @options[:input_encoding] = encoding
        end

        opts.on("-r", "--rows ROWS", Integer, "Max rows in output") do |rows|
          @options[:rows] = rows
        end

        opts.on("-o", "--outfile OUTFILE", "Write the result to the given file name") do |outfile|
          @options[:outfile] = outfile
        end

        # Grouping and mapping options
        opts.on("-g", "--group GROUP",
          "A file with a pre-defined set of layers. Data will be aggregated according to the group of layers.") do |group|
          @options[:group] = group
        end

        opts.on("-p", "--team-map-file TEAM_MAP_FILE",
          "A CSV file with author,team that translates individuals into teams.") do |team_map|
          @options[:team_map_file] = team_map
        end

        # Analysis threshold options
        opts.on("-n", "--min-revs MIN_REVS", Integer,
          "Minimum number of revisions to include an entity in the analysis (default: 5)") do |min_revs|
          @options[:min_revs] = min_revs
        end

        opts.on("-m", "--min-shared-revs MIN_SHARED_REVS", Integer,
          "Minimum number of shared revisions to include an entity in the analysis (default: 5)") do |min_shared|
          @options[:min_shared_revs] = min_shared
        end

        opts.on("-i", "--min-coupling MIN_COUPLING", Integer,
          "Minimum degree of coupling (in percentage) to consider (default: 30)") do |min_coupling|
          @options[:min_coupling] = min_coupling
        end

        opts.on("-x", "--max-coupling MAX_COUPLING", Integer,
          "Maximum degree of coupling (in percentage) to consider (default: 100)") do |max_coupling|
          @options[:max_coupling] = max_coupling
        end

        opts.on("-s", "--max-changeset-size MAX_CHANGESET_SIZE", Integer,
          "Maximum number of modules in a change set if it shall be included in a coupling analysis (default: 30)") do |max_size|
          @options[:max_changeset_size] = max_size
        end

        # Analysis-specific options
        opts.on("-e", "--expression-to-match MATCH_EXPRESSION",
          "A regex to match against commit messages. Used with -messages analyses") do |expression|
          @options[:expression_to_match] = expression
        end

        opts.on("-t", "--temporal-period TEMPORAL_PERIOD",
          "Used for coupling analyses. Instructs Ruby Maat to consider all commits during the rolling temporal period as a single, logical commit set") do |period|
          @options[:temporal_period] = period
        end

        opts.on("-d", "--age-time-now AGE_TIME_NOW",
          "Specify a date as YYYY-MM-dd that counts as time zero when doing a code age analysis") do |date_str|
          @options[:age_time_now] = Date.parse(date_str)
        rescue Date::Error
          raise ArgumentError, "Invalid date format for --age-time-now: #{date_str}. Use YYYY-MM-dd format."
        end

        opts.on("--verbose-results",
          "Includes additional analysis details together with the results. Only implemented for change coupling.") do
          @options[:verbose_results] = true
        end

        # Help and version
        opts.on("-h", "--help", "Show this help message") do
          @options[:help] = true
        end

        opts.on("--version", "Show version information") do
          puts VERSION_INFO
          exit 0
        end

        opts.on("--verbose", "Enable verbose error output") do
          @options[:verbose] = true
        end
      end
    end

    def usage_banner
      <<~BANNER
        #{VERSION_INFO}

        This is Ruby Maat, a Ruby port of Code Maat - a program used to collect statistics from a VCS.

        Usage: ruby-maat -l log-file -c vcs-type [options]

        Options:
      BANNER
    end

    def usage
      @parser.help
    end

    def validate_required_options!
      missing = []
      missing << "log file (-l/--log)" unless @options[:log]
      missing << "version control system (-c/--version-control)" unless @options[:version_control]

      raise ArgumentError, "Missing required options: #{missing.join(", ")}" unless missing.empty?

      # Set defaults
      @options[:analysis] ||= "authors"
      @options[:min_revs] ||= 5
      @options[:min_shared_revs] ||= 5
      @options[:min_coupling] ||= 30
      @options[:max_coupling] ||= 100
      @options[:max_changeset_size] ||= 30
    end
  end
end
