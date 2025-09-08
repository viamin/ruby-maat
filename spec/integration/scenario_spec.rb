# frozen_string_literal: true

require "stringio"

# Integration tests that verify ruby-maat produces output compatible with code-maat
# These tests use the same input files as the original Clojure tests
# rubocop:disable RSpec/DescribeClass
RSpec.describe "Integration scenarios" do
  # Test data files from the original code-maat test suite
  let(:git2_log_file) { "./spec/fixtures/code_maat/end_to_end/simple_git2.txt" }
  let(:empty_git_file) { "./spec/fixtures/code_maat/end_to_end/empty.git" }

  def run_ruby_maat(log_file, vcs, analysis, options = {})
    # Build command line arguments
    args = ["-l", log_file, "-c", vcs, "-a", analysis]

    # Add common test options
    args += ["-n", "1"] # min_revs
    args += ["-m", "1"] # min_shared_revs
    args += ["-i", "50"] # min_coupling

    # Add specific options
    args += ["--verbose-results"] if options[:verbose_results]
    args += ["-r", options[:rows].to_s] if options[:rows]

    # Capture output by running the CLI
    output = StringIO.new
    original_stdout = $stdout
    $stdout = output

    begin
      cli = RubyMaat::CLI.new
      cli.run(args)
    ensure
      $stdout = original_stdout
    end

    output.string
  end

  describe "Authors analysis with Git2" do
    it "produces expected output format and content" do
      output = run_ruby_maat(git2_log_file, "git2", "authors")

      expect(output).to include("entity,n-authors,n-revs")
      expect(output).to include("/Infrastrucure/Network/Connection.cs,2,2")
      expect(output).to include("/Presentation/Status/ClientPresenter.cs,1,1")

      lines = output.strip.split("\n")
      expect(lines.size).to eq(3) # header + 2 data rows
    end
  end

  describe "Revisions analysis with Git2" do
    it "produces expected output format and content" do
      output = run_ruby_maat(git2_log_file, "git2", "revisions")

      expect(output).to include("entity,n-revs")
      expect(output).to include("/Infrastrucure/Network/Connection.cs,2")
      expect(output).to include("/Presentation/Status/ClientPresenter.cs,1")

      lines = output.strip.split("\n")
      expect(lines.size).to eq(3) # header + 2 data rows
    end
  end

  describe "Coupling analysis with Git2" do
    it "produces expected output format and content" do
      output = run_ruby_maat(git2_log_file, "git2", "coupling")

      expect(output).to include("entity,coupled,degree,average-revs")
      expect(output).to include("/Infrastrucure/Network/Connection.cs,/Presentation/Status/ClientPresenter.cs")

      lines = output.strip.split("\n")
      expect(lines.size).to eq(2) # header + 1 coupling pair

      # Check the coupling degree is reasonable (should be around 66-67%)
      coupling_line = lines[1]
      degree = coupling_line.split(",")[2].to_i
      expect(degree).to be_between(66, 67)
    end

    it "supports verbose output" do
      output = run_ruby_maat(git2_log_file, "git2", "coupling", verbose_results: true)

      expect(output).to include("entity,coupled,degree,average-revs,first-entity-revisions,second-entity-revisions,shared-revisions")
      expect(output).to include(",2,1,1") # entity1_revs, entity2_revs, shared_revs

      lines = output.strip.split("\n")
      expect(lines.size).to eq(2) # header + 1 coupling pair
    end
  end

  describe "Empty log files" do
    it "handles empty Git logs for authors analysis" do
      output = run_ruby_maat(empty_git_file, "git2", "authors")
      expect(output.strip).to eq("entity,n-authors,n-revs")
    end

    it "handles empty Git logs for revisions analysis" do
      output = run_ruby_maat(empty_git_file, "git2", "revisions")
      expect(output.strip).to eq("entity,n-revs")
    end

    it "handles empty Git logs for coupling analysis" do
      output = run_ruby_maat(empty_git_file, "git2", "coupling")
      expect(output.strip).to eq("entity,coupled,degree,average-revs")
    end
  end

  describe "Command-line interface compatibility" do
    it "supports basic analysis selection" do
      # Test that we can call different analyses without errors
      expect { run_ruby_maat(git2_log_file, "git2", "authors") }.not_to raise_error
      expect { run_ruby_maat(git2_log_file, "git2", "revisions") }.not_to raise_error
      expect { run_ruby_maat(git2_log_file, "git2", "coupling") }.not_to raise_error
    end

    it "supports threshold parameters" do
      # Test with stricter thresholds - should produce less or no output
      args = ["-l", git2_log_file, "-c", "git2", "-a", "coupling", "-n", "5", "-m", "5", "-i", "80"]

      # rubocop:disable RSpec/ExpectOutput
      output = StringIO.new
      original_stdout = $stdout
      $stdout = output

      begin
        cli = RubyMaat::CLI.new
        cli.run(args)
      ensure
        $stdout = original_stdout
      end
      # rubocop:enable RSpec/ExpectOutput

      result = output.string
      lines = result.strip.split("\n")
      expect(lines.size).to eq(1) # Only header, no data rows due to strict thresholds
    end
  end
end
# rubocop:enable RSpec/DescribeClass
