# RUBY_MAAT.md

This file provides guidance to Claude Code (claude.ai/code) when working with the Ruby Maat codebase.

## Project Overview

Ruby Maat is a Ruby port of Code Maat, maintaining full backward compatibility while providing a modern Ruby implementation. It's designed as a drop-in replacement for the original Clojure version.

## Build and Development Commands

### Setting Up Development Environment

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run linting
bundle exec rubocop

# Auto-fix linting issues
bundle exec rubocop -a

# Run all checks
bundle exec rake
```

### Building and Installing

```bash
# Build gem
bundle exec rake build

# Install locally
bundle exec rake install

# Run the CLI locally
bundle exec exe/ruby-maat --help
```

### Testing

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/ruby_maat/analysis/authors_spec.rb

# Run with coverage
bundle exec rspec --format documentation

# Test specific functionality
bundle exec rspec --tag focus
```

## Architecture Overview

### Core Components

1. **Command Line Interface** (`lib/ruby_maat/cli.rb`)
   - Uses optparse for argument parsing
   - Maintains full backward compatibility with Code Maat CLI
   - Provides identical command-line arguments and behavior

2. **Application Core** (`lib/ruby_maat/app.rb`)
   - Main orchestration following same pipeline as original:
     - VCS Parsing → Data Grouping → Analysis → CSV Output
   - Registry pattern for analysis selection
   - Error handling and recovery

3. **Data Model**
   - `ChangeRecord` - Immutable value object for VCS changes
   - `Dataset` - Wrapper around Rover DataFrame for domain operations
   - Clean separation between data structures and business logic

4. **VCS Parsers** (`lib/ruby_maat/parsers/`)
   - Strategy pattern with base class and specific implementations
   - Identical input formats as original Code Maat
   - Error handling for malformed log files

5. **Analysis Modules** (`lib/ruby_maat/analysis/`)
   - Object-oriented design with base class and inheritance
   - Each analysis encapsulates domain logic
   - Rover DataFrame integration for statistical operations

6. **Data Processors** (`lib/ruby_maat/groupers/`)
   - Layer grouping for architectural boundaries
   - Temporal grouping for time-based analysis
   - Team mapping for organizational analysis

### Key Design Decisions

**Rover DataFrame Integration:**

- Replaces Incanter from original Clojure version
- Provides statistical computing capabilities
- Andrew Kane's excellent DataFrame library

**Object-Oriented Architecture:**

- Functional Clojure code translated to Ruby OOP
- Strategy pattern for parsers and analyses
- Immutable value objects where appropriate

**Backward Compatibility:**

- Identical CLI arguments and behavior
- Same CSV output format
- Compatible with existing scripts and workflows

### Analysis Modules

All analyses inherit from `BaseAnalysis` and implement `analyze(dataset, options)`:

**Core Analyses:**

- `Authors` - Developer count and revision metrics per entity
- `LogicalCoupling` - Entities that change together
- `Entities` - Basic revision counts
- `Summary` - High-level repository statistics

**Code Quality Analyses:**

- `Churn::*` - Various code churn metrics
- `Effort::*` - Developer effort and ownership patterns
- `CodeAge` - Time since last modification
- `SumOfCoupling` - Aggregated coupling metrics

**Social Analyses:**

- `Communication` - Developer collaboration patterns
- `CommitMessages` - Commit message word frequency

### Data Flow

1. **Parse** - VCS log files → Array of `ChangeRecord` objects
2. **Group** - Apply architectural/temporal/team grouping transformations
3. **Analyze** - Convert to `Dataset` and run analysis algorithms
4. **Output** - Format results as CSV using `CsvOutput`

### Ruby-Specific Patterns

**Enumerable Usage:**

- Heavy use of `map`, `filter`, `group_by`, `sort_by`
- Functional programming style within OOP structure

**Error Handling:**

- Consistent error messages and recovery
- Validation at boundaries (CLI, file parsing)
- Meaningful error messages for users

**Memory Efficiency:**

- Streaming CSV output
- Efficient data structures
- Garbage collection friendly

## Testing Strategy

**RSpec Structure:**

- Unit tests for each class and module
- Integration tests for end-to-end workflows
- Test data using `ChangeRecord` factories

**Key Test Areas:**

- Parser accuracy for all VCS formats
- Analysis algorithm correctness
- CLI argument parsing and validation
- Error handling and edge cases

**Test Data:**

- Small, focused datasets for unit tests
- Real-world patterns for integration tests
- Edge cases (empty files, malformed data, etc.)

## Development Guidelines

**Code Style:**

- Follow Ruby community conventions
- Use RuboCop for consistency
- Prefer explicit over implicit
- Clear method and variable names

**Performance:**

- Profile with large datasets during development
- Memory-conscious data structures
- Efficient algorithms for coupling analysis

**Compatibility:**

- Maintain CLI compatibility religiously
- Test against Code Maat output for regression
- Document any behavioral differences

## Integration with Original Code Maat

Ruby Maat is designed to be a seamless replacement:

**Input Compatibility:**

- Accepts identical VCS log file formats
- Same command-line arguments and flags
- Compatible option parsing and validation

**Output Compatibility:**

- Identical CSV column names and formats
- Same sorting and filtering behavior
- Matching precision for numerical results

**Feature Parity:**

- All 23 analysis types implemented
- Same grouping and mapping capabilities
- Identical error messages where possible

This makes Ruby Maat suitable for existing Code Maat workflows, scripts, and integrations without modification.
