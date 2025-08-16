# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ruby Maat is a Ruby port of Code Maat - a command-line tool for mining and analyzing data from version control systems (VCS). It extracts insights about code evolution, developer patterns, logical coupling, and code quality metrics from Git, SVN, Mercurial, Perforce, and TFS repositories.

**Key Feature**: Ruby Maat includes built-in log generation capabilities, allowing users to generate VCS logs directly without requiring external shell commands.

## Build and Development Commands

### Building the Project

```bash
# Install dependencies
bundle install

# Build gem
gem build ruby-maat.gemspec

# Run tests
bundle exec rspec
```

### Running Ruby Maat

```bash
# Run analysis on existing log file
ruby-maat -l logfile.log -c git -a authors

# Generate log file and save for future use
ruby-maat --generate-log --save-log my_log.log -c git

# Generate log and run analysis immediately
ruby-maat --generate-log -c git -a coupling

# Interactive log generation
ruby-maat --generate-log --interactive -c git

# Use preset configurations
ruby-maat --generate-log --preset git2-format -c git

# Show help and all available analyses
ruby-maat -h
```

### Log Generation

Ruby Maat can generate VCS logs directly, eliminating the need for manual log extraction:

**Available Presets:**
- `git2-format` - Standard format for git2 parser (recommended)
- `git-legacy` - Legacy format for git parser
- `recent-activity` - Last 3 months of activity
- `last-year` - Last 12 months of activity
- `full-history` - Complete repository history

**Supported VCS for Log Generation:**
- Git (both git and git2 formats)
- SVN (XML format)

**Interactive Mode Features:**
- Preset selection
- Custom date filtering
- Author filtering
- Path filtering
- Save or temporary log options

## Architecture Overview

### Core Components

1. **Command Line Interface** (`lib/ruby_maat/cli.rb`)
   - Entry point and argument parsing
   - Uses OptionParser for option handling
   - Handles both analysis and log generation modes

2. **Application Core** (`lib/ruby_maat/app.rb`)
   - Main orchestration logic following pipeline pattern:
     - Input → Parsers → Layer Mapping → Datasets → Analysis → Output
   - Contains registry of all supported analyses
   - Handles VCS parser selection and error recovery

3. **VCS Parsers** (`lib/ruby_maat/parsers/`)
   - Modular parsers for different VCS systems
   - `git2_parser.rb` - preferred Git parser (faster, more tolerant)
   - `git_parser.rb` - legacy Git parser (maintained for backward compatibility)
   - `svn_parser.rb`, `mercurial_parser.rb`, `perforce_parser.rb`, `tfs_parser.rb` - other VCS support

4. **Log Generators** (`lib/ruby_maat/generators/`) - **NEW FEATURE**
   - `base_generator.rb` - common functionality for all generators
   - `git_generator.rb` - Git log generation with presets and interactive mode
   - `svn_generator.rb` - SVN log generation with XML output
   - Support for preset configurations and custom options

5. **Analysis Modules** (`lib/ruby_maat/analysis/`)
   - Independent analysis implementations
   - Key analyses: authors, coupling, churn, code-age, communication, effort

6. **Data Processing** (`lib/ruby_maat/groupers/`)
   - `layer_grouper.rb` - maps files to architectural layers
   - `time_grouper.rb` - temporal aggregation
   - `team_mapper.rb` - maps authors to teams

7. **Output** (`lib/ruby_maat/output/`)
   - CSV output formatting
   - Filtering and row limiting

### Supported Analyses

Available via the `-a` parameter (see `SUPPORTED_ANALYSES` in `app.rb`):

- `authors` - developer count per module
- `coupling` - logical coupling between modules  
- `revisions` - revision count per entity
- `churn` - code churn metrics (abs-churn, author-churn, entity-churn)
- `age` - code age analysis
- `communication` - developer communication patterns
- `summary` - project overview statistics
- `effort` - developer effort distribution

### Data Flow

**Traditional Mode (with existing logs):**
1. Parse VCS log files into modification records
2. Optional aggregation by architectural boundaries (grouping files)
3. Optional temporal aggregation (group commits by time period)
4. Optional team mapping (map individual authors to teams)
5. Convert to dataset
6. Run analysis
7. Output results as CSV

**Log Generation Mode (NEW):**
1. Generate VCS log using appropriate generator
2. Either save log to file for future use, or pipe directly to analysis
3. Follow traditional data flow for analysis

### Key Dependencies

- Ruby 2.7+
- Standard Ruby libraries (optparse, date, fileutils, etc.)
- RSpec (for testing)

## Testing

Tests are located in `spec/` and follow the source structure. Key test categories:

- Unit tests for individual analysis modules
- Parser tests for different VCS formats
- Log generator tests with mocked VCS repositories
- CLI integration tests

Run all tests with `bundle exec rspec`.

## Development Notes

- The codebase follows object-oriented Ruby principles with functional influences
- All analysis modules are independent and composable  
- Parsers return arrays of ChangeRecord objects representing modifications
- Log generators use command execution with proper error handling
- Interactive mode provides user-friendly prompts and validation
- Memory usage can be high for large repositories - use date filtering presets
- Log generation supports both persistent and temporary modes for different workflows

## Log Generation Examples

```bash
# Quick analysis of recent Git activity
ruby-maat --generate-log --preset recent-activity -c git -a authors

# Interactive SVN log generation with custom options
ruby-maat --generate-log --interactive -c svn

# Generate and save Git log for later analysis
ruby-maat --generate-log --save-log project_history.log --preset full-history -c git

# Generate log and immediately run coupling analysis
ruby-maat --generate-log -c git -a coupling --min-revs 10
```
