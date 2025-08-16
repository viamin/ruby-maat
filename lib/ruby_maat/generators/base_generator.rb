# frozen_string_literal: true

require "fileutils"
require "tempfile"

module RubyMaat
  module Generators
    class BaseGenerator
      attr_reader :repository_path, :options

      def initialize(repository_path = ".", options = {})
        @repository_path = File.expand_path(repository_path)
        @options = options
        validate_repository!
      end

      def generate_log(output_file = nil, **generation_options)
        merged_options = @options.merge(generation_options)

        if output_file
          generate_persistent_log(output_file, merged_options)
        else
          generate_temporary_log(merged_options)
        end
      end

      def available_presets
        []
      end

      def interactive_generate
        puts "Interactive log generation for #{vcs_name}"
        puts "Repository: #{@repository_path}"
        puts

        preset = choose_preset
        options = gather_custom_options(preset)

        save_log = ask_yes_no("Save log to file for future use?")

        if save_log
          default_filename = default_log_filename
          filename = ask_string("Log filename", default_filename)
          generate_log(filename, **options)
        else
          generate_log(nil, **options)
        end
      end

      protected

      def vcs_name
        self.class.name.split("::").last.sub("Generator", "").downcase
      end

      def validate_repository!
        raise ArgumentError, "Repository path does not exist: #{@repository_path}" unless Dir.exist?(@repository_path)
      end

      def build_command(options)
        raise NotImplementedError, "Subclasses must implement build_command"
      end

      def execute_command(command)
        puts "Executing: #{command}" if @options[:verbose]

        result = `cd "#{@repository_path}" && #{command} 2>&1`
        exit_status = $?.exitstatus

        if exit_status != 0
          raise "Command failed with exit code #{exit_status}: #{result}"
        end

        result
      end

      def default_log_filename
        timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
        "#{vcs_name}_log_#{timestamp}.log"
      end

      private

      def generate_persistent_log(output_file, options)
        command = build_command(options)
        output = execute_command(command)

        File.write(output_file, output)
        puts "Log generated: #{output_file}" unless @options[:quiet]

        output_file
      end

      def generate_temporary_log(options)
        command = build_command(options)
        execute_command(command)
      end

      def choose_preset
        presets = available_presets

        if presets.empty?
          puts "No presets available for #{vcs_name}"
          return {}
        end

        puts "Available presets:"
        presets.each_with_index do |(name, description), index|
          puts "  #{index + 1}. #{name} - #{description[:description]}"
        end
        puts "  #{presets.length + 1}. Custom - Enter custom options"

        choice = ask_integer("Choose preset", 1, presets.length + 1)

        if choice <= presets.length
          preset_name = presets.keys[choice - 1]
          presets[preset_name][:options]
        else
          {}
        end
      end

      def gather_custom_options(base_options)
        options = base_options.dup

        puts "\nCustom options (press Enter to keep default):"

        if supports_date_filtering?
          since_date = ask_string("Since date (YYYY-MM-DD)", options[:since])
          options[:since] = since_date unless since_date.empty?

          until_date = ask_string("Until date (YYYY-MM-DD)", options[:until])
          options[:until] = until_date unless until_date.empty?
        end

        gather_vcs_specific_options(options)
      end

      def gather_vcs_specific_options(options)
        options
      end

      def supports_date_filtering?
        true
      end

      def ask_string(prompt, default = nil)
        default_text = default ? " [#{default}]" : ""
        print "#{prompt}#{default_text}: "
        response = $stdin.gets.chomp
        response.empty? ? (default || "") : response
      end

      def ask_integer(prompt, min = nil, max = nil)
        loop do
          response = ask_string(prompt)

          begin
            value = Integer(response)
            return value if (min.nil? || value >= min) && (max.nil? || value <= max)
            puts "Please enter a number between #{min} and #{max}"
          rescue ArgumentError
            puts "Please enter a valid number"
          end
        end
      end

      def ask_yes_no(prompt, default = nil)
        default_text = case default
        when true then " [Y/n]"
        when false then " [y/N]"
        else " [y/n]"
        end

        loop do
          response = ask_string("#{prompt}#{default_text}").downcase

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
    end
  end
end
