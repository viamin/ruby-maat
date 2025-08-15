# CI/CD Setup Documentation

This document describes the GitHub Actions CI/CD pipeline for the Ruby Maat project.

## Workflows

### 1. CI Workflow (`.github/workflows/ci.yml`)

Runs on every push and pull request to main/master branches.

#### Jobs

- **Test**: Runs RSpec tests across multiple Ruby versions (3.2, 3.3, 3.4) and operating systems (Ubuntu, macOS, Windows)
- **Lint**: Runs RuboCop and StandardRB linting
- **Security**: Runs Bundler Audit for security vulnerabilities
- **Integration**: Tests CLI functionality with sample data
- **Build**: Builds the gem and uploads it as an artifact

#### Matrix Testing

- Ruby versions: 3.2, 3.3, 3.4
- Operating systems: Ubuntu (all versions), macOS (all versions), Windows (Ruby 3.3 only)

### 2. Release Please Workflow (`.github/workflows/publish.yml`)

Runs on every push to main/master branches and uses conventional commits to automate releases.

#### How it works

1. **Release Please** analyzes conventional commits since the last release
2. **Creates Release PRs** when releasable changes are detected
3. **Merging a Release PR** triggers the actual release:
   - Updates version in `lib/ruby_maat/version.rb` and `ruby-maat.gemspec`
   - Generates/updates `CHANGELOG.md` automatically
   - Creates a GitHub release with the changelog
   - Runs full test suite and linting
   - Publishes gem to RubyGems.org
   - Uploads gem artifact to the release

## Required Secrets

To enable automatic publishing to RubyGems, add these secrets to your GitHub repository:

### RubyGems API Key

1. Get your API key from [RubyGems.org](https://rubygems.org/profile/edit)
2. Add it as a repository secret named `RUBYGEMS_API_KEY`

### GitHub Token

- `GITHUB_TOKEN` is automatically provided by GitHub Actions

## Environment Setup

The publish workflow uses a GitHub Environment named `rubygems` for additional security. To set this up:

1. Go to your repository Settings → Environments
2. Create an environment named `rubygems`
3. Add protection rules (recommended):
   - Required reviewers
   - Deployment branches (limit to main/master)

## Dependabot

Dependabot is configured to:

- Check for Ruby gem updates weekly (Sundays at 09:00)
- Check for GitHub Actions updates weekly
- Create PRs with appropriate labels and assignees

## Coverage Reporting

SimpleCov is configured to:

- Generate coverage reports for all test runs
- Group coverage by component (Analyses, Parsers, Output)
- Require minimum 50% coverage (adjustable in `spec/spec_helper.rb`)
- Upload coverage to Codecov (when CODECOV_TOKEN is set)

## Security Scanning

The CI pipeline includes:

- Bundler Audit for dependency vulnerabilities
- RuboCop security cops
- Dependabot security updates

## Local Development

To run the same checks locally:

```bash
# Install dependencies
bundle install

# Run tests with coverage
bundle exec rspec

# Run linting
bundle exec rubocop
bundle exec standardrb

# Run security audit
bundle exec bundler-audit

# Build gem
gem build ruby-maat.gemspec
```

## Triggering a Release

Release Please uses **conventional commits** to automatically determine version bumps and generate changelogs:

### Conventional Commit Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Commit Types

- `feat:` - New features (triggers minor version bump)
- `fix:` - Bug fixes (triggers patch version bump)
- `feat!:` or `BREAKING CHANGE:` - Breaking changes (triggers major version bump)
- `docs:`, `style:`, `refactor:`, `test:`, `chore:`, `ci:`, `deps:` - No version bump

### Release Process

1. **Make commits** using conventional commit format
2. **Push to main/master** - Release Please analyzes commits
3. **Review Release PR** - Automatically created when releasable changes exist
4. **Merge Release PR** - Triggers automatic release and publication

### Example Commits

```bash
git commit -m "feat(analysis): add new coupling algorithm"
git commit -m "fix(parser): handle empty git logs correctly"
git commit -m "docs: update CLI usage examples"
git commit -m "feat!: change CLI argument format" # breaking change
```

### Set up commit message template

```bash
git config commit.template .gitmessage
```

## Troubleshooting

### Gem Push Fails

- Verify `RUBYGEMS_API_KEY` secret is set correctly
- Ensure you have push permissions to the gem on RubyGems.org
- Check that the gem version hasn't been published already

### Test Failures

- Check the CI logs for specific failure reasons
- Ensure all dependencies are properly specified
- Test matrix may reveal OS or Ruby version specific issues

### Coverage Too Low

- Add tests for uncovered code
- Adjust minimum coverage threshold in `spec/spec_helper.rb` if needed
- Check coverage report in the `coverage/` directory after running tests

## Badge Status

Add these badges to your README to show CI status:

```markdown
![CI](https://github.com/viamin/ruby-maat/workflows/CI/badge.svg)
![Gem Version](https://badge.fury.io/rb/ruby-maat.svg)
```
