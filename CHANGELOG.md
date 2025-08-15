# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
