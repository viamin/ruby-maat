# frozen_string_literal: true

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

        rewrite_records(change_records, merge_map)
      end

      private

      def build_commit_info(records)
        commits = {}
        records.each do |record|
          rev = record.revision
          commits[rev] ||= {parents: record.parent_revisions || [], merge: false}
          commits[rev][:merge] = true if record.merge_commit?
        end
        commits
      end

      def build_merge_map(commits)
        merge_map = {}
        merges = commits.select { |_, info| info[:merge] }

        merges.each do |merge_rev, info|
          feature_parent = info[:parents][1]
          mainline_parent = info[:parents][0]
          next unless feature_parent && mainline_parent

          feature_commits = find_feature_commits(feature_parent, mainline_parent, commits)
          feature_commits.each { |rev| merge_map[rev] = merge_rev }
        end

        merge_map
      end

      # Walk backward from the feature branch tip, collecting commits that belong
      # to this merge. Stop when we reach the mainline parent or a commit not in
      # our log.
      def find_feature_commits(start, stop, commits)
        visited = Set.new
        queue = [start]

        while queue.any?
          current = queue.shift
          next if current == stop || visited.include?(current) || !commits.key?(current)

          visited << current

          parents = commits[current][:parents]
          parents&.each { |p| queue << p }
        end

        visited
      end

      def rewrite_records(records, merge_map)
        records.map do |record|
          merge_rev = merge_map[record.revision]
          if merge_rev
            ChangeRecord.new(
              entity: record.entity,
              author: record.author,
              date: record.date,
              revision: merge_rev,
              message: record.message,
              loc_added: record.loc_added,
              loc_deleted: record.loc_deleted
            )
          else
            record
          end
        end
      end
    end
  end
end
