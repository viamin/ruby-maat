# frozen_string_literal: true

require "optparse"
require "date"
require_relative "generators/git_generator"
require_relative "generators/svn_generator"
require_relative "analysis_presets"
require_relative "vcs_detector"

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

      if @options[:generate_log] || @options[:interactive]
        handle_log_generation
      else
        app = App.new(@options)
        app.run
      end
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

    def handle_log_generation
      if @options[:interactive]
        handle_interactive_mode
      else
        generator = create_log_generator
        output_file = @options[:save_log]
        preset_options = get_preset_options if @options[:preset]

        log_output = generator.generate_log(output_file, **(preset_options || {}))

        if output_file
          puts "Log generated: #{output_file}"
          # If we saved to file and analysis is specified, run analysis on that file
          if @options[:analysis] && @options[:analysis] != "authors"
            puts "\n=== Running Analysis ==="
            analysis_options = @options.merge(log: output_file)
            app = App.new(analysis_options)
            app.run
          end
        elsif log_output
          # If no output file specified and we have an analysis, run it on the generated log
          puts "\n=== Running Analysis ==="

          require "tempfile"
          temp_log = Tempfile.new(["ruby_maat", ".log"])
          temp_log.write(log_output)
          temp_log.close

          analysis_options = @options.merge(log: temp_log.path)
          app = App.new(analysis_options)
          app.run

          temp_log.unlink
        end
      end
    end

    def handle_interactive_mode
      unless $stdin.tty?
        raise "Interactive mode requires a terminal (TTY). Use --generate-log with presets instead."
      end

      puts "=== Ruby Maat Interactive Mode ==="
      puts

      # Step 1: Detect or choose VCS
      vcs_type = @options[:version_control] || detect_vcs_interactive

      # Step 2: Choose analysis type
      analysis_type = @options[:analysis] || choose_analysis_interactive

      # Step 3: Generate log and run analysis
      generator = create_log_generator_for_vcs(vcs_type)
      log_output = generator.interactive_generate_for_analysis(analysis_type, @options)

      # Step 4: Run analysis if log was generated to stdout
      if log_output && !@options[:save_log]
        puts "\n=== Running Analysis ==="

        # Create temporary log file for analysis
        require "tempfile"
        temp_log = Tempfile.new(["ruby_maat", ".log"])
        temp_log.write(log_output)
        temp_log.close

        # Run analysis
        analysis_options = @options.merge(
          log: temp_log.path,
          version_control: (vcs_type == "git") ? "git2" : vcs_type,
          analysis: analysis_type
        )

        app = App.new(analysis_options)
        app.run

        temp_log.unlink
      end
    end

    def create_log_generator
      case @options[:version_control]
      when "git", "git2"
        RubyMaat::Generators::GitGenerator.new(".", @options)
      when "svn"
        RubyMaat::Generators::SvnGenerator.new(".", @options)
      else
        raise ArgumentError, "Log generation not yet supported for #{@options[:version_control]}"
      end
    end

    def get_preset_options
      generator = create_log_generator
      presets = generator.available_presets

      unless presets.key?(@options[:preset])
        available = presets.keys.join(", ")
        raise ArgumentError, "Unknown preset '#{@options[:preset]}'. Available: #{available}"
      end

      presets[@options[:preset]][:options]
    end

    def create_log_generator_for_vcs(vcs_type)
      case vcs_type
      when "git", "git2"
        RubyMaat::Generators::GitGenerator.new(".", @options)
      when "svn"
        RubyMaat::Generators::SvnGenerator.new(".", @options)
      else
        raise ArgumentError, "Log generation not yet supported for #{vcs_type}"
      end
    end

    def detect_vcs_interactive
      detected = RubyMaat::VcsDetector.detect_vcs

      if detected
        puts "Detected VCS: #{RubyMaat::VcsDetector.vcs_description(detected)}"
        if ask_yes_no_interactive("Use detected VCS?", true)
          return detected
        end
      end

      choose_vcs_interactive
    end

    def choose_vcs_interactive
      puts "Choose version control system:"
      vcs_options = %w[git svn hg p4 tfs]
      vcs_options.each_with_index do |vcs, index|
        puts "  #{index + 1}. #{RubyMaat::VcsDetector.vcs_description(vcs)}"
      end

      choice = ask_integer_interactive("Choose VCS", 1, vcs_options.length)
      vcs_options[choice - 1]
    end

    def choose_analysis_interactive
      analyses = RubyMaat::AnalysisPresets.available_analyses

      puts "Choose analysis type:"
      analyses.each_with_index do |analysis, index|
        puts "  #{index + 1}. #{RubyMaat::AnalysisPresets.analysis_description(analysis)}"
      end

      choice = ask_integer_interactive("Choose analysis", 1, analyses.length)
      analyses[choice - 1]
    end

    def ask_yes_no_interactive(prompt, default = nil)
      default_text = case default
      when true then " [Y/n]"
      when false then " [y/N]"
      else " [y/n]"
      end

      loop do
        print "#{prompt}#{default_text}: "
        response = $stdin.gets
        return default if response.nil?
        response = response.chomp.downcase

        case response
        when "y", "yes"
          return true
        when "n", "no"
          return false
        when ""
          return default unless default.nil?
        end

        puts "Please enter 'y' or 'n'"
      end
    end

    def ask_integer_interactive(prompt, min = nil, max = nil)
      attempts = 0
      max_attempts = 10

      loop do
        attempts += 1
        if attempts > max_attempts
          raise "Too many invalid attempts. Exiting interactive mode."
        end

        print "#{prompt}: "
        response = $stdin.gets
        return 1 if response.nil? # Default to first option

        response = response.chomp

        if response.empty?
          puts "Please enter a valid number"
          next
        end

        begin
          value = Integer(response)
          return value if (min.nil? || value >= min) && (max.nil? || value <= max)
          puts "Please enter a number between #{min} and #{max}"
        rescue ArgumentError
          puts "Please enter a valid number"
        end
      end
    end

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

        # Log generation options
        opts.on("--generate-log", "Generate log file instead of running analysis") do
          @options[:generate_log] = true
        end

        opts.on("--save-log FILENAME", "Save generated log to file") do |filename|
          @options[:save_log] = filename
        end

        opts.on("--interactive", "Use interactive mode for log generation") do
          @options[:interactive] = true
        end

        opts.on("--preset PRESET", "Use a preset configuration for log generation") do |preset|
          @options[:preset] = preset
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

        Usage: 
          ruby-maat -l log-file -c vcs-type [options]           # Run analysis on existing log
          ruby-maat --generate-log -c vcs-type [options]        # Generate log file
          ruby-maat --generate-log --interactive -c vcs-type    # Interactive log generation

        Options:
      BANNER
    end

    def usage
      @parser.help
    end

    def validate_required_options!
      missing = []

      # In interactive mode, we can detect everything
      if @options[:interactive]
        # Interactive mode can work with no other options
        return
      end

      # Log file is only required when not generating logs
      unless @options[:generate_log] || @options[:log]
        missing << "log file (-l/--log)"
      end

      # VCS is required for non-interactive modes
      unless @options[:version_control]
        missing << "version control system (-c/--version-control)"
      end

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
