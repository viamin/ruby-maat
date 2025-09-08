# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.1](https://github.com/viamin/ruby-maat/compare/v1.3.0...v1.3.1) (2025-09-08)


### Bug Fixes

* **Gemfile.lock:** update ruby-maat version to 1.3.0 ([c5f8f1d](https://github.com/viamin/ruby-maat/commit/c5f8f1d659220d0db4015ac21fbb285d454a8a53))
* **release:** update version to 1.3.0 and enhance release-please configuration ([76c5222](https://github.com/viamin/ruby-maat/commit/76c5222720ee66c5e4238720c07f9e33edf1587e))
* **release:** update version to 1.3.0 and enhance release-please configuration ([6e96292](https://github.com/viamin/ruby-maat/commit/6e962922db3179f5b3d51c13db513ec89ea23fcb))


### Dependencies

* **deps:** bump rexml from 3.4.2 to 3.4.3 ([10300aa](https://github.com/viamin/ruby-maat/commit/10300aa75eca1441fa7a9d80b285f0195ca5c078))

## [1.3.0](https://github.com/viamin/ruby-maat/compare/v1.2.0...v1.3.0) (2025-09-03)


### Features

* add command preview functionality before execution ([3801f15](https://github.com/viamin/ruby-maat/commit/3801f15cf31cca8d519082ce78890efa4b5b9c65))
* add command preview functionality before execution ([499b3d5](https://github.com/viamin/ruby-maat/commit/499b3d5c929175d2e394d2877ff0ab30e973739e))


### Bug Fixes

* move release-type out of packages section of release-please-config ([ee87f5b](https://github.com/viamin/ruby-maat/commit/ee87f5b1a2e4d48ddc36ea516a9a968b23e75f39))

## [1.2.0](https://github.com/viamin/ruby-maat/compare/ruby-maat-v1.1.3...ruby-maat/v1.2.0) (2025-08-17)


### Features

* add CodeQL security analysis script and update configuration to exclude CodeQL artifacts ([d020fea](https://github.com/viamin/ruby-maat/commit/d020fea2485b456747f3546a6c6f59a8b31b63c4))
* add interactive log generation mode and enhance log generation options ([2375f04](https://github.com/viamin/ruby-maat/commit/2375f04625f2d101cb48b477728da45249e1f972))
* add rubocop-performance gem and improve shell command security with validation and escaping ([66f9791](https://github.com/viamin/ruby-maat/commit/66f97917bd4d57da7ce89e6eebbac28dd0326175))


### Bug Fixes

* 71 by documenting the format of the mapping files used for architectural analyses ([587f9d0](https://github.com/viamin/ruby-maat/commit/587f9d06e0cad5b9cb14c06aafdfe649870c9d5a))
* add missing ruby version file to extra-files in release config ([d565352](https://github.com/viamin/ruby-maat/commit/d56535266542396b9a124516ae3c5de1fb3926f5))
* add release-commit-message-scope configuration for CI ([59f1af1](https://github.com/viamin/ruby-maat/commit/59f1af1837cec33bed85f7a11bf0d56c9edb0a29))
* add release-commit-message-scope configuration for CI ([e580a05](https://github.com/viamin/ruby-maat/commit/e580a05c489d8a393c75d199ed01191591d84574))
* improve shell command execution and regex pattern for change detection ([0566796](https://github.com/viamin/ruby-maat/commit/05667963965cc137a3343ca492ffc1bf81791c37))
* update CHANGE_PATTERN regex for improved line matching in Git2Parser ([3ffc27c](https://github.com/viamin/ruby-maat/commit/3ffc27c4abde42494daff8f701aa38c1dffbb1eb))
* update permissions in CI workflows for better access control ([9c30839](https://github.com/viamin/ruby-maat/commit/9c30839ea3c8f6c7fee56d911231ebc27faa35df))
* update permissions in CI workflows for better access control ([be49302](https://github.com/viamin/ruby-maat/commit/be49302c98a16b528ebf56137667998382ce56c4))
* update regex patterns in parsers for improved matching ([d56ef8f](https://github.com/viamin/ruby-maat/commit/d56ef8fb93a433ffbafd74374966271bd6419ebc))
* version info for automations ([6d1dc43](https://github.com/viamin/ruby-maat/commit/6d1dc43f1b3bf666ca54b7d3c5999d63a7964cab))


### CI/CD

* **deps:** bump actions/checkout from 4 to 5 ([ab5ceac](https://github.com/viamin/ruby-maat/commit/ab5ceac8a3d6c633efa309bd58d355b3489afb4f))
* **deps:** bump codecov/codecov-action from 4 to 5 ([9b3c1dd](https://github.com/viamin/ruby-maat/commit/9b3c1dd4bb93fd024bd6a9c22160f602f4811391))


### Documentation

* Update README.md for on-prem pricing page ([e745abe](https://github.com/viamin/ruby-maat/commit/e745abece16b47adbb18d63fdaba39eb31c69204))


### Refactoring

* put a new on the complex behavior for organizing commits into sliding windows ([4829229](https://github.com/viamin/ruby-maat/commit/48292293652912af17835e1f31190ff720882dc2))
* Ruby Maat for Enhanced Log Generation and CLI Features ([de6123e](https://github.com/viamin/ruby-maat/commit/de6123ee827376d18ac8cd62a25da50debd755d7))
* Ruby Maat for Enhanced Log Generation and CLI Features ([e5a6410](https://github.com/viamin/ruby-maat/commit/e5a64105b45e88c89ccdb074befa9ece453666ea))
* update RSpec configuration and improve integration test handling ([b6895cb](https://github.com/viamin/ruby-maat/commit/b6895cb7e6ad9e1d53f836e1f7472a719372bd86))
* update RSpec tests to use `described_class` and improve mock handling ([033dbe3](https://github.com/viamin/ruby-maat/commit/033dbe3c483041f249f12f500fb7483447902fe0))


### Miscellaneous

* add extra-files configuration for version file in release-please ([2a1ae29](https://github.com/viamin/ruby-maat/commit/2a1ae29f1c898b78e426cc6c9c23340ea573e87e))
* **main:** release 1.1.0 ([befebb9](https://github.com/viamin/ruby-maat/commit/befebb9d2522d01b8cc6962b2ed43a3ba7507e4c))
* **main:** release 1.1.0 ([8160a68](https://github.com/viamin/ruby-maat/commit/8160a6836b063603b05bb0a81297ecb1d4cb29f5))
* **main:** release 1.1.1 ([a435b9c](https://github.com/viamin/ruby-maat/commit/a435b9ca99ffe79e89d5c5f378cf638930104a77))
* **main:** release 1.1.1 ([eb74e48](https://github.com/viamin/ruby-maat/commit/eb74e486ca7e750c72bb88edec4354c3f2239cc6))
* **main:** release 1.1.2 ([f3d6842](https://github.com/viamin/ruby-maat/commit/f3d6842d4a76fcaafdd7adc628c968174f616d6c))
* **main:** release 1.1.2 ([4535251](https://github.com/viamin/ruby-maat/commit/45352512ed80c992f9a9ecdab10513055e38a1d4))
* **main:** release 1.1.3 ([8bad82f](https://github.com/viamin/ruby-maat/commit/8bad82f5822aa1ef5f40f7a249dd30d449b69f4f))
* **main:** release 1.1.3 ([5a6552f](https://github.com/viamin/ruby-maat/commit/5a6552fd4e3a64b74dab6b075196573b3599fdf6))
* update CI workflows to include concurrency settings and adjust version to 1.1.2 ([a21698e](https://github.com/viamin/ruby-maat/commit/a21698e7bf49a2b4ee7a47e2311379ce60e5271a))
* update commitlint configuration and add Overcommit setup; implement commit message validation script ([890f3f5](https://github.com/viamin/ruby-maat/commit/890f3f519c564d0dd60990a22d844f203980959b))
* update GitHub Actions workflow for release process; add permissions and release type configuration ([e5dca27](https://github.com/viamin/ruby-maat/commit/e5dca27e32efa43f0ab677cd96e7cc2b56ce6fb0))
* update release configuration by removing inline settings and adding dedicated config file ([240ba2a](https://github.com/viamin/ruby-maat/commit/240ba2a7962d1bb286a79d4b3c63199053037b95))
* update ruby-maat version to 1.1.2 in Gemfile.lock ([bf5bfa7](https://github.com/viamin/ruby-maat/commit/bf5bfa7e996a82af23c40acd70236774026b7cde))

## [1.1.3](https://github.com/viamin/ruby-maat/compare/v1.1.2...v1.1.3) (2025-08-17)


### Bug Fixes

* add missing ruby version file to extra-files in release config ([d565352](https://github.com/viamin/ruby-maat/commit/d56535266542396b9a124516ae3c5de1fb3926f5))

## [1.1.2](https://github.com/viamin/ruby-maat/compare/v1.1.1...v1.1.2) (2025-08-17)


### Bug Fixes

* update permissions in CI workflows for better access control ([9c30839](https://github.com/viamin/ruby-maat/commit/9c30839ea3c8f6c7fee56d911231ebc27faa35df))
* update permissions in CI workflows for better access control ([be49302](https://github.com/viamin/ruby-maat/commit/be49302c98a16b528ebf56137667998382ce56c4))

## [1.1.1](https://github.com/viamin/ruby-maat/compare/v1.1.0...v1.1.1) (2025-08-16)


### Bug Fixes

* add release-commit-message-scope configuration for CI ([59f1af1](https://github.com/viamin/ruby-maat/commit/59f1af1837cec33bed85f7a11bf0d56c9edb0a29))
* add release-commit-message-scope configuration for CI ([e580a05](https://github.com/viamin/ruby-maat/commit/e580a05c489d8a393c75d199ed01191591d84574))

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
