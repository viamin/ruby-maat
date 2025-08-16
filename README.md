# Ruby Maat

Ruby Maat is a command line tool used to mine and analyze data from version-control systems (VCS). It's a Ruby port of the original [Code Maat](https://github.com/adamtornhill/code-maat) by Adam Tornhill.

**Note:** The analyses have evolved into [CodeScene](https://codescene.io/), which automates all the analyses found in Ruby Maat and several new ones.

## Drop-in Replacement for Code Maat + Log Generation

Ruby Maat is designed as a **drop-in replacement** for the original Code Maat with enhanced capabilities:

- ✅ Identical command-line arguments
- ✅ Same VCS log file formats*
- ✅ Compatible CSV output format
- ✅ All original analysis types
- 🆕 **Built-in log generation** - No need for manual VCS commands
- 🆕 **Interactive mode** with guided log creation
- 🆕 **Preset configurations** for common scenarios

`*` In theory. I've only tested with git.

Simply replace `java -jar code-maat.jar` with `ruby-maat` in your existing scripts, or use the new log generation features for a streamlined workflow.

## Installation

### Via RubyGems (Recommended)

```bash
gem install ruby-maat
```

### Via Docker

```bash
docker build -t ruby-maat .

# Traditional mode with existing logs
docker run -v /path/to/your/logs:/data ruby-maat -l /data/logfile.log -c git2 -a summary

# NEW: Log generation mode (mount your repository)
docker run -v /path/to/your/repo:/repo ruby-maat --generate-log --preset recent-activity -c git -a coupling
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

## License

Distributed under the [GNU General Public License v3.0](http://www.gnu.org/licenses/gpl.html).

## Usage

### Basic Usage

#### Traditional Mode (with existing logs)
```bash
# Analyze Git repository
ruby-maat -l logfile.log -c git2 -a summary

# With specific analysis
ruby-maat -l logfile.log -c git2 -a coupling

# Write to file
ruby-maat -l logfile.log -c git2 -a authors -o results.csv
```

#### New: Log Generation Mode
```bash
# Generate log and analyze immediately
ruby-maat --generate-log -c git -a authors

# Generate log with preset and save for later
ruby-maat --generate-log --preset recent-activity --save-log my_log.log -c git

# Interactive mode with guided setup
ruby-maat --generate-log --interactive -c git

# Generate log and run specific analysis
ruby-maat --generate-log --preset git2-format -c git -a coupling --min-revs 10
```

### Command Line Options

When invoked with `-h`, Ruby Maat prints its usage:

```
Usage: 
  ruby-maat -l log-file -c vcs-type [options]           # Run analysis on existing log
  ruby-maat --generate-log -c vcs-type [options]        # Generate log file
  ruby-maat --generate-log --interactive -c vcs-type    # Interactive log generation

Required:
  -c, --version-control VCS        Input vcs module type: supports svn, git, git2, hg, p4, or tfs
  -l, --log LOG                    Log file with input data (not required with --generate-log)

Log Generation (NEW):
      --generate-log               Generate log file instead of running analysis
      --save-log FILENAME          Save generated log to file
      --interactive                Use interactive mode for log generation
      --preset PRESET              Use a preset configuration for log generation
                                   Git presets: git2-format, git-legacy, recent-activity, last-year, full-history
                                   SVN presets: standard, recent-activity, last-year, date-range, revision-range

Analysis:
  -a, --analysis ANALYSIS          The analysis to run (default: authors)
                                   Available: abs-churn, age, author-churn, authors, communication, 
                                   coupling, entity-churn, entity-effort, entity-ownership, 
                                   fragmentation, identity, main-dev, main-dev-by-revs, messages, 
                                   refactoring-main-dev, revisions, soc, summary

Filtering:
  -n, --min-revs MIN_REVS          Minimum number of revisions (default: 5)
  -m, --min-shared-revs MIN_SHARED Minimum shared revisions (default: 5)
  -i, --min-coupling MIN_COUPLING  Minimum coupling percentage (default: 30)
  -x, --max-coupling MAX_COUPLING  Maximum coupling percentage (default: 100)
  -s, --max-changeset-size SIZE    Maximum changeset size (default: 30)

Output:
  -r, --rows ROWS                  Max rows in output
  -o, --outfile OUTFILE            Write the result to the given file name
      --input-encoding ENCODING    Specify an encoding other than UTF-8 for the log file

Other:
  -h, --help                       Show this help message
      --version                    Show version information
```

### Generating input data

Ruby Maat operates on log files from version-control systems. You have **two options**:

1. **🆕 NEW: Automatic log generation** - Ruby Maat can generate logs for you
2. **Traditional: Manual log generation** - Use VCS commands directly (same as original Code Maat)

#### Option 1: Automatic Log Generation (Recommended)

Ruby Maat can generate VCS logs automatically with built-in presets and interactive guidance:

```bash
# Quick start - analyze recent Git activity
ruby-maat --generate-log --preset recent-activity -c git -a summary

# Interactive mode with guided setup
ruby-maat --generate-log --interactive -c git

# Generate and save SVN log for later use
ruby-maat --generate-log --preset standard --save-log svn_history.log -c svn
```

**Available Presets:**

**Git Presets:**
- `git2-format` - Standard format for git2 parser (recommended)
- `git-legacy` - Legacy format for git parser  
- `recent-activity` - Last 3 months of activity
- `last-year` - Last 12 months of activity
- `full-history` - Complete repository history

**SVN Presets:**
- `standard` - Standard SVN XML log format
- `recent-activity` - Last 3 months of activity
- `last-year` - Last 12 months of activity
- `date-range` - Custom date range (interactive)
- `revision-range` - Specific revision range (interactive)

**Interactive Mode Features:**
- Preset selection with descriptions
- Custom date filtering (YYYY-MM-DD format)
- Author filtering
- Path filtering  
- Branch selection (Git)
- Save or temporary log options

#### Option 2: Manual Log Generation (Traditional)

For compatibility with existing workflows, you can still generate logs manually. **Use the exact same commands as the original Code Maat.** The supported version-control systems are `git`, Mercurial (`hg`), `svn`, Perforce (`p4`), and Team Foundation Server (`tfs`).

#### Preparations

To analyze our VCS data we need to define a temporal period of interest. Over time, many design issues do get fixed and we don't want old data to interfere with our current analysis of the code. To limit the data Ruby Maat will consider, use one of the following flags depending on your version-control system:

- *git:* Use the `--after=<date>` to specify the last date of interest. The `<date>` is given as `YYYY-MM-DD`.
- *hg:* Use the `--date` switch to specify the last date of interest. The value is given as `">YYYY-MM-DD"`.
- *svn:* Use the `-r` option to specify a range of interest, for example `-r {20130820}:HEAD`.
- *p4:* Use the `-m` option to specify the last specified number of changelists, for example `-m 1000`.
- *tfs:* Use the `/stopafter` option to specify the number of changesets, for example `/stopafter:1000`

#### ⚠️ Windows user? Use GitBASH when interacting with Ruby Maat

Ruby Maat expects its Git logs to have UNIX line endings. If you're on windows, then the simplest solution
is to interact with Git through a Git BASH shell that emulates a Linux environment. The Git BASH shell is distributed together with Git itself.

#### Generate a Subversion log file using the following command

          svn log -v --xml > logfile.log -r {YYYYmmDD}:HEAD

#### Generate a git log file using the following command

The first options is the legacy format used in Your Code As A Crime Scene. Use the `-c git` parse option when running Ruby Maat.

          git log --pretty=format:'[%h] %aN %ad %s' --date=short --numstat --after=YYYY-MM-DD > logfile.log

There's a second supported Git format as well. It's more tolerant and faster to parse, so please prefer it over the plain `git` format described above. Use the `-c git2` parse option when running Ruby Maat.

          git log --all --numstat --date=short --pretty=format:'--%h--%ad--%aN' --no-renames --after=YYYY-MM-DD > logfile.log

Many codebases include third-party content or non-code artefacts,  which might generate noise in the analyses.
You can exclude such content via git's pathspecs that limit paths on the command line.
For example, let's say you want to exclude everything in a `vendor/ folder`. You would then append the following pattern to the `git log` commands above:

           -- . ":(exclude)vendor/*"

To exclude multiple folders, you just append more pathspecs:

           -- . ":(exclude)vendor/" ":(exclude)test/"

#### Generate a Mercurial log file using the following command

          hg log --template "rev: {rev} author: {author} date: {date|shortdate} files:\n{files %'{file}\n'}\n" --date ">YYYY-MM-DD"

#### Generate a Perforce log file using the following command

          p4 changes -s submitted -m 5000 //depot/project/... | cut -d ' ' -f 2 | xargs -I commitid -n1 sh -c 'p4 describe -s commitid | grep -v "^\s*$" && echo ""'

#### Generate a TFS log file using the following command from a Developer command-prompt

###### Note:  The TFS CLI tool does not support custom date formatting.  The parser currently only supports the en-us default:  Friday, January 1, 2016 1:12:35 PM - you may need to adjust your system locale settings before using the following command

          tf hist /path/to/workspace /noprompt /format:detailed /recursive

### Running Ruby Maat

#### Traditional Mode (with existing logs)

If you've installed the gem:

       ruby-maat -l logfile.log -c <vcs>

If you've built a docker container:

        docker run -v /home/xx/src/logs:/data -it ruby-maat -l /data/logfile.log -c <vcs>

#### NEW: Log Generation Mode

Generate logs automatically:

       ruby-maat --generate-log -c <vcs> -a <analysis>

With Docker (mount your repository):

        docker run -v /path/to/repo:/repo -it ruby-maat --generate-log -c <vcs> -a <analysis>

When invoked with `-h`, Ruby Maat prints its usage. (See the [Command Line Options](#command-line-options) section above for details.)

### Optional: specify an encoding

By default, Ruby Maat expects your log files to be UTF-8. If you use another encoding, override the default with `--input-encoding`, for example `--input-encoding UTF-16BE`.

#### Generating a summary

When starting out, I find it useful to get an overview of the mined data. With the `summary` analysis, Ruby Maat produces such an overview:

       ruby-maat -l logfile.log -c git -a summary

The resulting output is on csv format:

              statistic,                 value
              number-of-commits,           919
              number-of-entities,          730
              number-of-entities-changed, 3397
              number-of-authors,            79

If you use the second Git format, just specify `git2` instead:

       ruby-maat -l logfile2.log -c git2 -a summary

#### Mining organizational metrics

By default, Ruby Maat runs an analysis on the number of authors per module. The authors analysis is based on the idea that the more developers working on a module, the larger the communication challenges. The analysis is invoked with the following command:

       ruby-maat -l logfile.log -c git

The resulting output is on CSV format:

              entity,         n-authors, n-revs
              InfoUtils.java, 12,        60
              BarChart.java,   7,        30
              Page.java,       4,        27
              ...

In example above, the first column gives us the name of module, the second the total number of distinct authors that have made commits on that module, and the third column gives us the total number of revisions of the module. Taken together, these metrics serve as predictors of defects and quality issues.

#### Mining logical coupling

Logical coupling refers to modules that tend to change together. Modules that are logically coupled have a hidden, implicit dependency between them such that a change to one of them leads to a predictable change in the coupled module. To analyze the logical coupling in a system, invoke Ruby Maat with the following arguments:

              ruby-maat -l logfile.log -c git -a coupling

The resulting output is on CSV format:

              entity,          coupled,        degree,  average-revs
              InfoUtils.java,  Page.java,      78,      44
              InfoUtils.java,  BarChart.java,  62,      45
              ...

In the example above, the first column (`entity`) gives us the name of the module, the second (`coupled`) gives us the name of a logically
coupled module, the third column (`degree`) gives us the coupling as a percentage (0-100), and finally `average-revs` gives us the average number of revisions
of the two modules.

To interpret the data, consider the `InfoUtils.java` module in the example output above.
The coupling tells us that each time it's modified, it's a 78% risk/chance that we'll have to change our `Page.java` module too.
Since there's probably no reason they should change together, the analysis points to a part of the code worth investigating as a potential target for a future refactoring.

*Advanced*: the coupling analysis also supports `--verbose-results`. In verbose mode, the coupling analysis also includes the number of revisions for each coupled entity together
with the number of shared revisions. The main use cases for this option are a) build custom filters to reduce noise, or b) research studies.

### Calculate code age

The change frequency of code is a factor that should (but rarely do) drive the evolution of a software architecture. In general, you want to stabilize as much code as possible. A failure to stabilize means that you need to maintain a working knowledge of those parts of the code for the life-time of the system.

One way to measure the stability of a software architecture is by a code age analysis:

              ruby-maat -l logfile.log -c git -a age

The `age` analysis grades each module based on the date of last change. The measurement unit is age in months. Here's how the result may look:

              entity,age-months
              src/code_maat/app/app.clj,2
              project.clj,4
              src/code_maat/parsers/perforce.clj,5
              ...

By default, Ruby Maat uses the current date as starting point for a code age analysis. You specify a different start time with the command line argument `--age-time-now`.

By using the techniques from [Your Code as a Crime Scene](https://pragprog.com/book/atcrime/your-code-as-a-crime-scene) we visualize the system with each module marked-up by its age (the more `red`, the more recent changes to the code):

![code age visualized](doc/imgs/code_age_sample.png).

## Code churn measures

Code churn is related to post-release defects. Modules with higher churn tend to have more defects. There are several different aspects of code churn. I intend to support several of them in Code Maat.

### Absolute churn

The absolute code churn numbers are calculated with the `-a abs-churn` option. Note that the option is only available for `git`. The analysis will output a CSV table with the churn accumulated per date:

             date,       added, deleted
             2013-08-09,   259,      20
             2013-08-19,   146,      77
             2013-08-21,     5,       6
             2013-08-20,   773,     121
             2013-08-30,   349,     185
             ...

Visualizing the result allows us to spot general trends over time:

![abs churn visualized](doc/imgs/abs_churn_sample.png).

### Churn by author

The idea behind this analysis is to get an idea of the overall contributions by each individual. The analysis is invoked with the `-a author-churn` option. The result will be given as CSV:

             author,        added, deleted
             Adam Tornhill, 13826,    1670
             Some One Else,   123,      80
             Mr Petersen,       3,       3
             ...

And, of course, you wouldn't use this data for any performance evaluation; it wouldn't serve well (in case anything should be rewarded it would be a net deletion of code - there's too much of it in the world).

### Churn by entity

The pre-release churn of a module is a good predictor of its number of post-release defects. Such an analysis is supported in Code Maat by the `-a entity-churn` option.

Note: Some research suggests that relative churn measures are better, while others don't find any significant differences. The metrics calculated by Code Maat are absolute for now because it's easier to calculate. I'm likely to include support for relative churn too.

## Ownership patterns

Once we have mined the organizational metrics described above, we may find we have multiple developers working on the same modules. How is their effort distributed? Does a particular module have a major developer or is everyone contributing a small piece? Let's find out by running the `-a entity-ownership` analysis. This analysis gives us the following output:

             entity,               author,  added, deleted
             analysis/authors.clj,    apt,    164,      98
             analysis/authors.clj,    qew,     81,      10
             analysis/authors.clj,     jt,     42,      32
             analysis/entities.clj,   apt,     72,      24
             ...

Another ownership view is to consider the effort spent by individual authors on the different entities in the system. This analysis is run by the `-a entity-effort` option. The analysis gives us the following table:

             entity,                author, author-revs, total-revs
             analysis/authors.clj,     apt,           5,         10
             analysis/authors.clj,     qew,           3,         10
             analysis/authors.clj,      jt,           1,         10
             analysis/authors.clj,     apt,           1,         10
             ...

This information may be a useful guide to find the right author to discuss functionality and potential refactorings with. Just note that the ownership metrics are sensitive to the same biases as the churn metrics; they're both heuristics and no absolute truths.

## Temporal periods

Sometimes we'd like to find patterns that manifests themselves over multiple commits. Code Maat provides the `--temporal-period` switch that let you consider all commits within a day as a logical change. Just provide the switch and add a digit - in the future that digit may even mean something; Right now the aggregation is limited to commits within a single day.

## Architectural level analyses

Using the `-g` flag lets you specify a mapping from individual files to logical components. This feature makes it possible to
scale the analyses to an architectural level and get hotspots, knowledge metrics, etc. on the level of sub-systems.

There are some sample mapping files in the `end_to_end` test folder, for
example [this one](https://github.com/adamtornhill/code-maat/blob/ebd2b757ae31510b5cf52d0e11fafa82a7e062d1/test/code_maat/end_to_end/regex-and-text-layers-definition.txt)

The format is `regex_pattern => logical_group_name`:

```
src/Features/Core      => Core
^src\/.*\/.*Tests\.cs$ => CS Tests
```

Code Maat takes everything that matches a regex and analyses it as a
holistic whole by aggregating all file contributions for the matches.

### Intermediate results

Code Maat supports an `identity` analysis. By using this switch, Code Maat will output the intermediate parse result of the raw VCS file. This can be useful either as a debug aid or as input to other tools.

## Limitations

Ruby Maat processes all its content in memory, which may not scale to very large input files. The recommendation is to limit the input by specifying a sensible start date using the VCS date filtering options (as discussed above, you want to do that anyway to avoid confounds in the analysis).

For extremely large repositories (>100k commits), the original Java/Clojure version may have better memory management, but Ruby Maat should handle most real-world repositories without issues.

### Windows Compatibility

**Note for Windows users**: Ruby Maat currently has dependencies on native extensions (`numo-narray`) that may have compilation issues on Windows with certain Ruby versions. If you encounter installation problems:

1. **Use WSL2** (Windows Subsystem for Linux) for the best experience
2. **Use Docker** as an alternative: `docker run -v /path/to/logs:/data ruby-maat -l /data/logfile.log -c git2 -a summary`
3. **Check the Issues page** for current workarounds and updates on Windows compatibility

## Development

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b my-new-feature`)
3. **Set up git hooks** (recommended):

   ```bash
   # Install Overcommit git hooks (Ruby-native alternative to pre-commit)
   bundle exec overcommit --install
   
   # Note: If you encounter Ruby 3.4 compatibility issues, you can:
   # 1. Use Ruby 3.3 or earlier, or
   # 2. Run quality checks manually: bundle exec rspec && bundle exec standardrb
   ```

4. Make your changes following the existing code style
5. Add tests for your changes
6. **Use conventional commit messages**:

   ```text
   feat: add new analysis type for code complexity
   fix: resolve parsing issue with binary files
   docs: update installation instructions
   test: add integration tests for coupling analysis
   ```

7. Run the test suite (`bundle exec rspec`)
8. Run the linter (`bundle exec standardrb`)
9. Commit your changes (git hooks will run automatically)
10. Push to the branch (`git push origin my-new-feature`)
11. Create a new Pull Request

#### Conventional Commit Format

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automated versioning and changelog generation. **All new commits must follow this format**:

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

**Scopes**: `analysis`, `parser`, `output`, `cli`, `dataset`, `grouper`, `core`, `deps`, `ci`

**Examples**:

- `feat(analysis): add new complexity analysis algorithm`
- `fix(parser): handle binary files correctly in git2 parser`
- `docs: update installation instructions for Windows users`
- `test(integration): add end-to-end tests for coupling analysis`

> **Note**: This project transitioned to conventional commits for Release Please automation. Historical commits may not follow this format, but all new contributions must use conventional commit messages.

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/ruby_maat/analysis/authors_spec.rb

# Run with coverage
bundle exec rspec --format documentation
```

### Code Style

This project uses [StandardRB](https://github.com/testdouble/standard) for Ruby style enforcement:

```bash
# Check style
bundle exec standardrb

# Auto-fix style issues
bundle exec standardrb --fix
```

## Acknowledgments

Ruby Maat is a Ruby port of the original [Code Maat](https://github.com/adamtornhill/code-maat) by Adam Tornhill.
