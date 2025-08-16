# frozen_string_literal: true

module RubyMaat
  module VcsDetector
    def self.detect_vcs(path = ".")
      expanded_path = File.expand_path(path)

      # Check for Git
      git_dir = File.join(expanded_path, ".git")
      if Dir.exist?(git_dir) || File.exist?(git_dir)
        return "git"
      end

      # Check for SVN
      svn_dir = File.join(expanded_path, ".svn")
      if Dir.exist?(svn_dir)
        return "svn"
      end

      # Check for Mercurial
      hg_dir = File.join(expanded_path, ".hg")
      if Dir.exist?(hg_dir)
        return "hg"
      end

      # Check for Perforce (look for .p4config or ask p4)
      p4config = File.join(expanded_path, ".p4config")
      if File.exist?(p4config)
        return "p4"
      end

      # Try to detect by running commands (if they exist)
      begin
        Dir.chdir(expanded_path) do
          # Check git status
          `git status 2>/dev/null`
          return "git" if $?.exitstatus == 0

          # Check svn info
          `svn info 2>/dev/null`
          return "svn" if $?.exitstatus == 0

          # Check hg status
          `hg status 2>/dev/null`
          return "hg" if $?.exitstatus == 0

          # Check p4 info
          `p4 info 2>/dev/null`
          return "p4" if $?.exitstatus == 0
        end
      rescue
        # If we can't change directory or run commands, continue
      end

      nil # No VCS detected
    end

    def self.vcs_description(vcs)
      case vcs
      when "git"
        "Git repository"
      when "svn"
        "Subversion repository"
      when "hg"
        "Mercurial repository"
      when "p4"
        "Perforce repository"
      when "tfs"
        "Team Foundation Server"
      else
        "Unknown VCS"
      end
    end
  end
end
