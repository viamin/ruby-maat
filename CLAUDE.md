# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Code Maat is a command-line tool for mining and analyzing data from version control systems (VCS). It extracts insights about code evolution, developer patterns, logical coupling, and code quality metrics from Git, SVN, Mercurial, Perforce, and TFS repositories.

## Build and Development Commands

### Building the Project

```bash
# Build standalone JAR (primary method)
lein uberjar

# Run directly via Leiningen (for development)
lein run -l logfile.log -c <vcs>

# Build Docker image
docker build -t code-maat-app .

# Run tests
lein test
```

### Running Code Maat

```bash
# Using standalone JAR
java -jar code-maat-1.0.5-SNAPSHOT-standalone.jar -l logfile.log -c <vcs>

# Using Docker
docker run -v /host/path:/data -it code-maat-app -l /data/logfile.log -c <vcs>

# Show help and all available analyses
java -jar code-maat-1.0.5-SNAPSHOT-standalone.jar -h
```

### Memory Configuration

Code Maat is memory-intensive. The project.clj includes these JVM options:

- `-Xmx4g` (4GB heap)
- `-Djava.awt.headless=true` (suppress AWT frames)
- `-Xss512M` (512MB stack size)

## Architecture Overview

### Core Components

1. **Command Line Interface** (`src/code_maat/cmd_line.clj`)
   - Entry point and argument parsing
   - Uses clojure.tools.cli for option handling

2. **Application Core** (`src/code_maat/app/app.clj`)
   - Main orchestration logic following pipeline pattern:
     - Input → Parsers → Layer Mapping → Incanter Datasets → Analysis → Output
   - Contains registry of all supported analyses
   - Handles VCS parser selection and error recovery

3. **VCS Parsers** (`src/code_maat/parsers/`)
   - Modular parsers for different VCS systems
   - `git2.clj` - preferred Git parser (faster, more tolerant)
   - `git.clj` - legacy Git parser (maintained for backward compatibility)
   - `svn.clj`, `mercurial.clj`, `perforce.clj`, `tfs.clj` - other VCS support

4. **Analysis Modules** (`src/code_maat/analysis/`)
   - Independent analysis implementations
   - Each returns Incanter datasets
   - Key analyses: authors, coupling, churn, code-age, communication, effort

5. **Data Processing** (`src/code_maat/app/`)
   - `grouper.clj` - maps files to architectural layers
   - `time_based_grouper.clj` - temporal aggregation
   - `team_mapper.clj` - maps authors to teams

6. **Output** (`src/code_maat/output/`)
   - CSV output formatting
   - Filtering and row limiting

### Supported Analyses

Available via the `-a` parameter (see `supported-analysis` map in `app.clj:55`):

- `authors` - developer count per module
- `coupling` - logical coupling between modules  
- `revisions` - revision count per entity
- `churn` - code churn metrics (abs-churn, author-churn, entity-churn)
- `age` - code age analysis
- `communication` - developer communication patterns
- `summary` - project overview statistics
- `effort` - developer effort distribution

### Data Flow

1. Parse VCS log files into modification records
2. Optional aggregation by architectural boundaries (grouping files)
3. Optional temporal aggregation (group commits by time period)
4. Optional team mapping (map individual authors to teams)
5. Convert to Incanter dataset
6. Run analysis
7. Output results as CSV

### Key Dependencies

- Clojure 1.8.0
- Incanter (statistical computing)
- clojure.tools.cli (command line parsing)
- clj-time (date/time handling)
- instaparse (parsing DSL)

## Testing

Tests are located in `test/code_maat/` and follow the source structure. Key test categories:

- Unit tests for individual analysis modules
- End-to-end scenario tests with sample VCS data
- Parser tests for different VCS formats

Run all tests with `lein test`.

## Development Notes

- The codebase follows functional programming principles
- All analysis modules are independent and composable  
- Parsers return sequences of maps representing modifications
- Heavy use of Incanter for dataset operations
- Error handling with recovery points for user-friendly messages
- Memory usage can be high for large repositories - consider date filtering
