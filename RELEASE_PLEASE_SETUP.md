# Release Please Setup

This document explains how the automated release system works using Google's Release Please.

## Overview

Release Please automates:

- ✅ **Version bumping** based on conventional commits
- ✅ **CHANGELOG generation** from commit messages  
- ✅ **Release creation** with proper Git tags
- ✅ **Gem publishing** to RubyGems.org
- ✅ **GitHub release** with artifacts

## How It Works

### 1. Conventional Commits

Developers use conventional commit format:

```bash
git commit -m "feat(parser): add SVN log support"
git commit -m "fix(analysis): handle empty datasets correctly"
git commit -m "docs: update CLI examples"
```

### 2. Release Please Analysis

On every push to main/master:

- Analyzes commits since last release
- Determines if a release is needed
- Calculates version bump (patch/minor/major)

### 3. Release PR Creation

When releasable changes exist:

- Creates/updates a "Release PR"
- Updates version files
- Generates/updates CHANGELOG.md
- Ready for review and approval

### 4. Automated Publishing

When Release PR is merged:

- Creates GitHub release with tag
- Publishes gem to RubyGems.org
- Uploads gem artifact to release

## Configuration Files

### `.release-please-config.json`

- Package configuration
- Version file locations
- Changelog sections
- Extra files to update

### `.release-please-manifest.json`

- Tracks current version
- Updated automatically by Release Please

### `.commitlintrc.json`

- Validates conventional commit format
- Enforces consistent commit messages
- Runs on pull requests

### `.gitmessage`

- Commit message template
- Set up with: `git config commit.template .gitmessage`

## Conventional Commit Types

| Type | Description | Version Bump |
|------|-------------|--------------|
| `feat:` | New feature | Minor |
| `fix:` | Bug fix | Patch |
| `feat!:` | Breaking change | Major |
| `BREAKING CHANGE:` | Breaking change | Major |
| `docs:` | Documentation | None |
| `style:` | Code style | None |
| `refactor:` | Code refactoring | None |
| `test:` | Tests | None |
| `chore:` | Maintenance | None |
| `ci:` | CI/CD changes | None |
| `deps:` | Dependencies | None |

## Common Scopes

- `analysis` - Analysis modules
- `parser` - VCS parsers
- `output` - Output formatters
- `cli` - Command-line interface
- `dataset` - Data handling
- `core` - Core functionality

## Example Workflow

1. **Feature Development**:

   ```bash
   git commit -m "feat(analysis): add complexity metrics analysis"
   git commit -m "test(analysis): add tests for complexity metrics"
   git commit -m "docs(analysis): document complexity analysis options"
   ```

2. **Push to Main**:

   ```bash
   git push origin main
   ```

3. **Release Please Actions**:
   - Analyzes commits
   - Creates Release PR titled "chore(main): release 1.1.0"
   - Updates version from 1.0.0 → 1.1.0
   - Adds feature to CHANGELOG.md

4. **Review & Merge**:
   - Review the generated changelog
   - Merge the Release PR
   - Automatic publishing begins

5. **Published Release**:
   - GitHub release created with tag v1.1.0
   - Gem published to RubyGems.org
   - Gem artifact attached to release

## Benefits Over Manual Releases

- ✅ **No version conflicts** - automated version management
- ✅ **Consistent changelogs** - generated from commits
- ✅ **Enforced conventions** - conventional commit validation
- ✅ **Zero-downtime releases** - automated testing before publish
- ✅ **Release approval** - review before publishing via Release PR
- ✅ **Atomic releases** - all-or-nothing publishing

## Troubleshooting

### No Release PR Created

- Check if commits follow conventional format
- Ensure commits contain releasable changes (`feat:`, `fix:`, etc.)
- Verify `.release-please-config.json` is valid

### Release PR Not Publishing

- Check RubyGems API key secret is set
- Verify tests pass in CI
- Ensure gem version isn't already published

### Version Not Updated

- Check `version-file` path in config
- Verify `extra-files` configuration for gemspec
- Ensure Release PR was merged, not just closed

## Manual Override

To create a release manually:

```bash
# Trigger release-please workflow manually
gh workflow run publish.yml

# Or create a conventional commit that forces a release
git commit -m "chore: trigger release" --allow-empty
git push origin main
```

## Getting Started

1. **Set up commit template**:

   ```bash
   git config commit.template .gitmessage
   ```

2. **Use conventional commits**:

   ```bash
   git commit -m "feat(cli): add new --format option"
   ```

3. **Push changes**:

   ```bash
   git push origin main
   ```

4. **Wait for Release PR** and review/merge when ready

That's it! The rest is automated. 🚀
