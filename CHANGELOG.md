# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0](https://github.com/viamin/ruby-maat/compare/v1.0.0...v1.1.0) (2025-08-16)


### Features

* add CodeQL security analysis script and update configuration to exclude CodeQL artifacts ([d020fea](https://github.com/viamin/ruby-maat/commit/d020fea2485b456747f3546a6c6f59a8b31b63c4))
* add interactive log generation mode and enhance log generation options ([2375f04](https://github.com/viamin/ruby-maat/commit/2375f04625f2d101cb48b477728da45249e1f972))
* add rubocop-performance gem and improve shell command security with validation and escaping ([66f9791](https://github.com/viamin/ruby-maat/commit/66f97917bd4d57da7ce89e6eebbac28dd0326175))


### Bug Fixes

* improve shell command execution and regex pattern for change detection ([0566796](https://github.com/viamin/ruby-maat/commit/05667963965cc137a3343ca492ffc1bf81791c37))
* update CHANGE_PATTERN regex for improved line matching in Git2Parser ([3ffc27c](https://github.com/viamin/ruby-maat/commit/3ffc27c4abde42494daff8f701aa38c1dffbb1eb))
* update regex patterns in parsers for improved matching ([d56ef8f](https://github.com/viamin/ruby-maat/commit/d56ef8fb93a433ffbafd74374966271bd6419ebc))

## [1.0.0] - 2024-08-15

### Added

- Initial Ruby port of Code Maat
- Support for all VCS parsers: Git, Git2, SVN, Mercurial, Perforce, TFS
- Complete analysis suite:
  - Authors analysis
  - Entities analysis  
  - Logical coupling analysis
  - Sum of coupling analysis
  - Code churn analysis (absolute, by author, by entity, ownership)
  - Effort analysis (by revisions, main developer, fragmentation)
  - Communication analysis
  - Code age analysis
  - Commit messages analysis
  - Summary analysis
- Data grouping capabilities:
  - Layer grouping (architectural boundaries)
  - Temporal grouping (time-based aggregation)
  - Team mapping (author-to-team mapping)
- Command-line interface with full backward compatibility
- CSV output format
- Comprehensive RSpec test suite
- Ruby 3.2+ support
- Rover DataFrame integration for statistical computing

### Changed

- Ported from Clojure to Ruby while maintaining API compatibility
- Replaced Incanter with Rover DataFrame for statistical operations
- Converted from functional to object-oriented architecture

### Technical Notes

- Drop-in replacement for original Code Maat
- Identical command-line arguments and CSV output format
- Improved memory efficiency through Ruby's garbage collection
- Enhanced error handling and validation
