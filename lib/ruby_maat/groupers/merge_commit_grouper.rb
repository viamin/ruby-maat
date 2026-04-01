# frozen_string_literal: true

# NOTE: Set has been a built-in class (autoloaded without require) since
# Ruby 3.2, which is this project's minimum version (see gemspec:
# required_ruby_version >= "3.2.0").  An explicit `require "set"` is
# unnecessary and triggers RuboCop's Lint/RedundantRequireStatement cop.

module RubyMaat
  module Groupers
    # Groups commits by their merge commit to enable PR-level coupling analysis.
    #
    # When Git uses a merge-based workflow (e.g., GitHub PRs), individual commits
    # on feature branches are combined into merge commits on the main branch.
    # This grouper identifies merge commits and rewrites the revision of child
    # commits so that all commits belonging to a merge share the same revision.
    #
    # This allows the coupling analysis to treat all files changed in a PR as
    # co-changing, giving more meaningful coupling results.
    #
    # Requires log data generated with parent hashes:
    #   git log --all --numstat --date=short --pretty=format:'--%h--%p--%ad--%aN--%s' --no-renames
    class MergeCommitGrouper
      def group(change_records)
        commit_info = build_commit_info(change_records)
        merge_map = build_merge_map(commit_info)

        return change_records if merge_map.empty?

        merge_dates = build_merge_dates(commit_info)
        rewrite_records(change_records, merge_map, merge_dates)
      end

      private

      def build_commit_info(records)
        commits = {}
        records.each do |record|
          rev = record.revision
          commits[rev] ||= {parents: record.parent_revisions || [], merge: false, date: record.date}
          commits[rev][:merge] = true if record.merge_commit?
        end
        commits
      end

      def build_merge_map(commits)
        merge_map = {}
        merges = commits.select { |_, info| info[:merge] }

        merges.each do |merge_rev, info|
          parents = info[:parents] || []
          mainline_parent = parents[0]
          next unless mainline_parent && parents.length > 1

          # Handle octopus merges (3+ parents) by iterating all feature parents
          feature_parents = parents[1..].compact
          feature_parents.each do |feature_parent|
            feature_commits = find_feature_commits(feature_parent, mainline_parent, commits)
            feature_commits.each { |rev| merge_map[rev] = merge_rev }
          end
        end

        merge_map
      end

      # Walk backward from the feature branch tip, collecting commits that belong
      # to this merge. Excludes any commits reachable from the mainline parent so
      # that intermediate merges from main into the feature branch don't pull in
      # unrelated mainline history.
      def find_feature_commits(start, stop, commits)
        mainline_ancestors = collect_ancestors(stop, commits)
        visited = Set.new
        queue = [start]
        head = 0

        while head < queue.length
          current = queue[head]
          head += 1
          next if mainline_ancestors.include?(current) || visited.include?(current) || !commits.key?(current)

          visited << current

          parents = commits[current][:parents]
          parents&.each { |p| queue << p }
        end

        visited
      end

      # Collect all ancestors reachable from a given commit (inclusive).
      def collect_ancestors(start, commits)
        ancestors = Set.new
        queue = [start]
        head = 0

        while head < queue.length
          current = queue[head]
          head += 1
          next if ancestors.include?(current) || !commits.key?(current)

          ancestors << current

          parents = commits[current][:parents]
          parents&.each { |p| queue << p }
        end

        ancestors
      end

      # Build a lookup from merge revision to its date, used to align
      # rewritten feature-branch records with the merge commit's date.
      def build_merge_dates(commits)
        dates = {}
        commits.each do |rev, info|
          dates[rev] = info[:date] if info[:merge]
        end
        dates
      end

      def rewrite_records(records, merge_map, merge_dates)
        records.map do |record|
          merge_rev = merge_map[record.revision]
          if merge_rev
            ChangeRecord.new(
              entity: record.entity,
              author: record.author,
              date: merge_dates[merge_rev] || record.date,
              revision: merge_rev,
              message: record.message,
              loc_added: record.loc_added,
              loc_deleted: record.loc_deleted,
              parent_revisions: record.parent_revisions
            )
          else
            record
          end
        end
      end
    end
  end
end
