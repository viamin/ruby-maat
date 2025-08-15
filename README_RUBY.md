# Ruby Maat

[![Gem Version](https://badge.fury.io/rb/ruby-maat.svg)](https://badge.fury.io/rb/ruby-maat)
[![Build Status](https://github.com/viamin/ruby-maat/workflows/CI/badge.svg)](https://github.com/viamin/ruby-maat/actions)

Ruby Maat is a command line tool used to mine and analyze data from version-control systems (VCS). It's a Ruby port of the original [Code Maat](https://github.com/adamtornhill/code-maat) by Adam Tornhill.

Ruby Maat was developed to accompany the discussions in the books [Your Code as a Crime Scene](https://pragprog.com/titles/atcrime/your-code-as-a-crime-scene) and [Software Design X-Rays](https://pragprog.com/titles/atevol/software-design-x-rays).

**Note:** The analyses have evolved into [CodeScene](https://codescene.io/), which automates all the analyses found in Ruby Maat and several new ones.

## Drop-in Replacement

Ruby Maat is designed as a **drop-in replacement** for Code Maat. It supports:
- ✅ Identical command-line arguments
- ✅ Same VCS log file formats  
- ✅ Compatible CSV output format
- ✅ All original analysis types

Simply replace `java -jar code-maat.jar` with `ruby-maat` in your existing scripts!

## Installation

### Via RubyGems (Recommended)

```bash
gem install ruby-maat
```

### From Source

```bash
git clone https://github.com/viamin/ruby-maat.git
cd ruby-maat
bundle install
rake install
```

### Requirements

- Ruby 3.2 or later
- No external dependencies beyond the gem requirements

## Usage

### Basic Usage

```bash
# Analyze Git repository
ruby-maat -l logfile.log -c git2 -a summary

# With specific analysis
ruby-maat -l logfile.log -c git2 -a coupling

# Write to file
ruby-maat -l logfile.log -c git2 -a authors -o results.csv
```

### Command Line Options

```
Usage: ruby-maat -l log-file -c vcs-type [options]

Required:
  -l, --log LOG                    Log file with input data
  -c, --version-control VCS        Input vcs module type: supports svn, git, git2, hg, p4, or tfs

Analysis:
  -a, --analysis ANALYSIS          The analysis to run (default: authors)
                                   Available: abs-churn, age, author-churn, authors, communication, 
                                   coupling, entity-churn, entity-effort, entity-ownership, 
                                   fragmentation, identity, main-dev, main-dev-by-revs, messages, 
                                   refactoring-main-dev, revisions, soc, summary

Output:
  -r, --rows ROWS                  Max rows in output
  -o, --outfile OUTFILE            Write the result to the given file name
      --input-encoding ENCODING    Specify an encoding other than UTF-8 for the log file

Grouping:
  -g, --group GROUP                A file with a pre-defined set of layers
  -p, --team-map-file TEAM_MAP     A CSV file with author,team mappings
  -t, --temporal-period PERIOD     Group commits by temporal period

Filtering:
  -n, --min-revs MIN_REVS          Minimum number of revisions (default: 5)
  -m, --min-shared-revs MIN_SHARED Minimum shared revisions (default: 5)
  -i, --min-coupling MIN_COUPLING  Minimum coupling percentage (default: 30)
  -x, --max-coupling MAX_COUPLING  Maximum coupling percentage (default: 100)
  -s, --max-changeset-size SIZE    Maximum changeset size (default: 30)

Analysis-specific:
  -e, --expression-to-match REGEX  Regex for commit message analysis
  -d, --age-time-now DATE          Reference date for age analysis (YYYY-MM-dd)
      --verbose-results            Include additional analysis details

Other:
  -h, --help                       Show this help message
      --version                    Show version information
```

## Generating Input Data

Ruby Maat operates on log files from version-control systems. **Use the exact same commands as Code Maat:**

### Git (Recommended: git2 format)

```bash
git log --all --numstat --date=short --pretty=format:'--%h--%ad--%aN' --no-renames --after=YYYY-MM-DD > logfile.log
```

Then use `-c git2` when running Ruby Maat.

### Git (Legacy format)

```bash
git log --pretty=format:'[%h] %aN %ad %s' --date=short --numstat --after=YYYY-MM-DD > logfile.log
```

Then use `-c git` when running Ruby Maat.

### Subversion

```bash
svn log -v --xml > logfile.log -r {YYYYmmDD}:HEAD
```

### Other VCS Systems

Ruby Maat supports the same log formats as Code Maat for:
- Mercurial (`hg`)
- Perforce (`p4`)
- Team Foundation Server (`tfs`)

See the [original documentation](https://github.com/adamtornhill/code-maat#generating-input-data) for specific commands.

## Available Analyses

| Analysis | Description |
|----------|-------------|
| `authors` | Number of authors per module (default) |
| `revisions` | Number of revisions per entity |
| `coupling` | Logical coupling between modules |
| `soc` | Sum of coupling per entity |
| `summary` | High-level project statistics |
| `abs-churn` | Absolute code churn over time |
| `author-churn` | Code churn per author |
| `entity-churn` | Code churn per entity |
| `entity-ownership` | Code ownership per author per entity |
| `main-dev` | Main developer per entity (by lines) |
| `main-dev-by-revs` | Main developer per entity (by commits) |
| `entity-effort` | Development effort per author per entity |
| `fragmentation` | Ownership fragmentation (fractal value) |
| `communication` | Developer communication patterns |
| `age` | Code age analysis |
| `messages` | Commit message word frequency |
| `identity` | Raw data dump (debugging) |

## Examples

### Authors Analysis
```bash
ruby-maat -l git.log -c git2 -a authors
```
Output:
```csv
entity,n-authors,n-revs
InfoUtils.java,12,60
BarChart.java,7,30
Page.java,4,27
```

### Logical Coupling
```bash
ruby-maat -l git.log -c git2 -a coupling
```
Output:
```csv
entity,coupled,degree,average-revs
InfoUtils.java,Page.java,78,44
InfoUtils.java,BarChart.java,62,45
```

### Summary Statistics
```bash
ruby-maat -l git.log -c git2 -a summary
```
Output:
```csv
statistic,value
number-of-commits,919
number-of-entities,730
number-of-entities-changed,3397
number-of-authors,79
```

## Advanced Features

### Architectural Grouping

Group files into architectural layers:

```
# layers.txt
src/Features/Core      => Core
^src\/.*\/.*Tests\.cs$ => CS Tests
```

```bash
ruby-maat -l git.log -c git2 -a coupling -g layers.txt
```

### Team Analysis

Map individual authors to teams:

```csv
# teams.csv
author,team
john.doe,Backend Team
jane.smith,Frontend Team
```

```bash
ruby-maat -l git.log -c git2 -a authors -p teams.csv
```

### Temporal Analysis

Group commits by time period:

```bash
ruby-maat -l git.log -c git2 -a coupling -t day
```

## Differences from Code Maat

While Ruby Maat is a drop-in replacement, there are some minor differences:

### Advantages
- **Faster startup**: No JVM startup time
- **Better memory efficiency**: Ruby's garbage collection
- **Easier installation**: No Java dependencies
- **Native Ruby integration**: Use as a library in Ruby projects

### Performance
- Ruby Maat may be slightly slower on very large datasets
- For most repositories, performance is comparable
- Memory usage is typically lower than the JVM version

## Development

### Running Tests

```bash
bundle install
bundle exec rspec
```

### Code Quality

```bash
bundle exec rubocop
```

### Building the Gem

```bash
bundle exec rake build
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/viamin/ruby-maat.

## License

Ruby Maat is distributed under the [GNU General Public License v3.0](http://www.gnu.org/licenses/gpl.html), the same license as the original Code Maat.

## Acknowledgments

- **Adam Tornhill** - Original Code Maat author and creator of the analysis algorithms
- **Code Maat contributors** - For the foundational work this port is based on

## About the Name

Like the original Code Maat, this tool is named after Maat, the ancient Egyptian goddess of truth, justice, and order. Ruby Maat continues Maat's work of bringing order to chaotic codebases, now in Ruby.