# frozen_string_literal: true

require "tempfile"

RSpec.describe RubyMaat::Parsers::Git2Parser do
  describe "merge commit detection" do
    context "with standard format (message-based detection)" do
      let(:log_with_merges) do
        <<~LOG
          --abc123--2023-01-15--John Doe--Merge pull request #42 from feature/add-login
          10      5       src/main.rb
          2       0       src/login.rb

          --def456--2023-01-14--Jane Smith--Add login form
          15      3       src/login.rb

          --ghi789--2023-01-13--Jane Smith--Merge branch 'hotfix'
          8       2       src/main.rb

          --jkl012--2023-01-12--Bob Wilson--Regular commit
          5       1       src/helper.rb
        LOG
      end

      let(:temp_file) do
        file = Tempfile.new(["git2_merge_log", ".log"])
        file.write(log_with_merges)
        file.close
        file
      end

      after { temp_file.unlink }

      it "detects merge commits from message patterns" do
        parser = described_class.new(temp_file.path)
        records = parser.parse

        merge_records = records.select(&:merge_commit)
        non_merge_records = records.reject(&:merge_commit)

        # "Merge pull request #42" and "Merge branch 'hotfix'" are merges
        expect(merge_records.map(&:revision).uniq).to contain_exactly("abc123", "ghi789")
        # "Add login form" and "Regular commit" are not merges
        expect(non_merge_records.map(&:revision).uniq).to contain_exactly("def456", "jkl012")
      end

      it "preserves all other record fields" do
        parser = described_class.new(temp_file.path)
        records = parser.parse

        merge_record = records.find { |r| r.revision == "abc123" }
        expect(merge_record.entity).to eq("src/main.rb")
        expect(merge_record.author).to eq("John Doe")
        expect(merge_record.message).to eq("Merge pull request #42 from feature/add-login")
        expect(merge_record.merge_commit).to be true
      end
    end

    context "with enhanced format (parent-based detection)" do
      let(:log_with_parents) do
        # Enhanced format uses PARENTS: sentinel + tab between parents and subject
        "--abc123--2023-01-15--John Doe--PARENTS:def456 aabb99\tMerge pull request #42\n" \
        "10      5       src/main.rb\n" \
        "\n" \
        "--ccd012--2023-01-14--Jane Smith--PARENTS:eef345\tRegular commit\n" \
        "15      3       src/helper.rb\n"
      end

      let(:temp_file) do
        file = Tempfile.new(["git2_parents_log", ".log"])
        file.write(log_with_parents)
        file.close
        file
      end

      after { temp_file.unlink }

      it "detects merge commits from multiple parent hashes" do
        parser = described_class.new(temp_file.path)
        records = parser.parse

        merge_record = records.find { |r| r.revision == "abc123" }
        regular_record = records.find { |r| r.revision == "ccd012" }

        expect(merge_record.merge_commit).to be true
        expect(regular_record.merge_commit).to be false
      end

      it "uses parent count as authoritative signal, ignoring merge-like messages" do
        # A single-parent commit with a merge-like subject should NOT be flagged as a merge
        # when parent hashes are available (parent count is authoritative in enhanced format)
        log = "--aaa111--2023-01-15--John Doe--PARENTS:bbb222\tMerge feature into main\n" \
              "10      5       src/main.rb\n"
        file = Tempfile.new(["git2_parent_authority", ".log"])
        file.write(log)
        file.close

        parser = described_class.new(file.path)
        records = parser.parse
        file.unlink

        expect(records.first.merge_commit).to be false
        expect(records.first.message).to eq("Merge feature into main")
      end
    end

    context "with enhanced format root commits (no parents)" do
      let(:log_with_root_commit) do
        # Enhanced format uses PARENTS: sentinel + tab between parents and subject
        "--abc123--2023-01-15--John Doe--PARENTS:def456 aabb99\tMerge pull request #42\n" \
        "10      5       src/main.rb\n" \
        "\n" \
        "--ccd012--2023-01-14--Jane Smith--PARENTS:eef345\tRegular commit\n" \
        "15      3       src/helper.rb\n" \
        "\n" \
        "--root01--2023-01-01--Jane Smith--PARENTS:\tInitial commit\n" \
        "20      0       README.md\n"
      end

      let(:temp_file) do
        file = Tempfile.new(["git2_root_log", ".log"])
        file.write(log_with_root_commit)
        file.close
        file
      end

      after { temp_file.unlink }

      it "parses root commits with empty parents as non-merge" do
        parser = described_class.new(temp_file.path)
        records = parser.parse

        root_record = records.find { |r| r.revision == "root01" }
        expect(root_record).not_to be_nil
        expect(root_record.merge_commit).to be false
        expect(root_record.message).to eq("Initial commit")
        expect(root_record.entity).to eq("README.md")
      end

      it "still detects merge commits correctly alongside root commits" do
        parser = described_class.new(temp_file.path)
        records = parser.parse

        merge_record = records.find { |r| r.revision == "abc123" }
        regular_record = records.find { |r| r.revision == "ccd012" }

        expect(merge_record.merge_commit).to be true
        expect(regular_record.merge_commit).to be false
      end
    end

    context "with standard format subjects containing tricky patterns" do
      let(:log_with_tricky_subject) do
        # Standard format: subject starts with hex-like text and contains '--' or tabs
        # These must NOT be misparsed as enhanced format with parents
        "--abc123--2023-01-15--John Doe--deadbeef--fix edge case\n" \
        "10      5       src/main.rb\n" \
        "\n" \
        "--def456--2023-01-14--Jane Smith--cafe0123 babe4567--some description\n" \
        "15      3       src/helper.rb\n" \
        "\n" \
        "--ghi789--2023-01-13--Bob Wilson--deadbeef\tsomething with a tab\n" \
        "8       2       src/other.rb\n"
      end

      let(:temp_file) do
        file = Tempfile.new(["git2_tricky_log", ".log"])
        file.write(log_with_tricky_subject)
        file.close
        file
      end

      after { temp_file.unlink }

      it "parses as standard format without misidentifying parents" do
        parser = described_class.new(temp_file.path)
        records = parser.parse

        record1 = records.find { |r| r.revision == "abc123" }
        expect(record1).not_to be_nil
        expect(record1.message).to eq("deadbeef--fix edge case")
        expect(record1.merge_commit).to be false

        record2 = records.find { |r| r.revision == "def456" }
        expect(record2).not_to be_nil
        expect(record2.message).to eq("cafe0123 babe4567--some description")
        expect(record2.merge_commit).to be false

        # Hex-like start with tab: must NOT match enhanced format (no PARENTS: sentinel)
        record3 = records.find { |r| r.revision == "ghi789" }
        expect(record3).not_to be_nil
        expect(record3.message).to eq("deadbeef\tsomething with a tab")
        expect(record3.merge_commit).to be false
      end
    end

    context "with various merge message patterns" do
      def parse_single_commit(message)
        log = "--abc123--2023-01-15--John Doe--#{message}\n10\t5\tsrc/main.rb\n"
        file = Tempfile.new(["git2_pattern_log", ".log"])
        file.write(log)
        file.close

        parser = described_class.new(file.path)
        records = parser.parse
        file.unlink
        records.first
      end

      it "detects 'Merge pull request #N' pattern" do
        record = parse_single_commit("Merge pull request #123 from owner/branch")
        expect(record.merge_commit).to be true
      end

      it "detects 'Merge branch' with single quotes" do
        record = parse_single_commit("Merge branch 'feature/new-thing'")
        expect(record.merge_commit).to be true
      end

      it "detects 'Merge branch' with double quotes" do
        record = parse_single_commit('Merge branch "feature/new-thing"')
        expect(record.merge_commit).to be true
      end

      it "detects 'Merge remote-tracking branch' pattern" do
        record = parse_single_commit("Merge remote-tracking branch 'origin/main'")
        expect(record.merge_commit).to be true
      end

      it "detects 'Merge X into Y' pattern" do
        record = parse_single_commit("Merge feature into main")
        expect(record.merge_commit).to be true
      end

      it "does not flag regular commits as merges" do
        record = parse_single_commit("Add merge sort implementation")
        expect(record.merge_commit).to be false
      end
    end
  end
end
