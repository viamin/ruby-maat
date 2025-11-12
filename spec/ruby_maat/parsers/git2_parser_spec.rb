# frozen_string_literal: true

require "tempfile"

RSpec.describe RubyMaat::Parsers::Git2Parser do
  let(:sample_git2_log) do
    <<~LOG
      --abc123--2023-01-15--John Doe--Add new feature
      10      5       src/main.rb
      2       0       test/test_main.rb

      --def456--2023-01-16--Jane Smith--Fix helper bug
      15      3       lib/helper.rb
      -       -       binary_file.png

      --ghi789--2023-01-17--Bob Wilson--Refactor main module
      8       2       src/main.rb
    LOG
  end

  let(:temp_file) do
    file = Tempfile.new(["git2_log", ".log"])
    file.write(sample_git2_log)
    file.close
    file
  end

  after { temp_file.unlink }

  describe "#parse" do
    it "parses git2 log format correctly" do
      parser = described_class.new(temp_file.path)
      records = parser.parse

      expect(records.size).to eq(4)

      # First commit - first file
      first_record = records[0]
      expect(first_record.entity).to eq("src/main.rb")
      expect(first_record.author).to eq("John Doe")
      expect(first_record.date).to eq(Date.parse("2023-01-15"))
      expect(first_record.revision).to eq("abc123")
      expect(first_record.message).to eq("Add new feature")
      expect(first_record.loc_added).to eq(10)
      expect(first_record.loc_deleted).to eq(5)

      # First commit - second file
      second_record = records[1]
      expect(second_record.entity).to eq("test/test_main.rb")
      expect(second_record.author).to eq("John Doe")
      expect(second_record.revision).to eq("abc123")
      expect(second_record.message).to eq("Add new feature")
      expect(second_record.loc_added).to eq(2)
      expect(second_record.loc_deleted).to eq(0)

      # Second commit - helper file
      third_record = records[2]
      expect(third_record.entity).to eq("lib/helper.rb")
      expect(third_record.author).to eq("Jane Smith")
      expect(third_record.revision).to eq("def456")
      expect(third_record.message).to eq("Fix helper bug")
      expect(third_record.loc_added).to eq(15)
      expect(third_record.loc_deleted).to eq(3)

      # Third commit
      fourth_record = records[3]
      expect(fourth_record.entity).to eq("src/main.rb")
      expect(fourth_record.author).to eq("Bob Wilson")
      expect(fourth_record.revision).to eq("ghi789")
      expect(fourth_record.message).to eq("Refactor main module")
    end

    it "handles binary files (- indicators)" do
      parser = described_class.new(temp_file.path)
      records = parser.parse

      # Should skip binary files with - indicators
      binary_records = records.select { |r| r.entity == "binary_file.png" }
      expect(binary_records).to be_empty
    end

    it "skips empty lines" do
      log_with_empty_lines = <<~LOG
        --abc123--2023-01-15--John Doe--Add feature

        10      5       src/main.rb

        --def456--2023-01-16--Jane Smith--Fix bug
        15      3       lib/helper.rb
      LOG

      file = Tempfile.new(["git2_log_empty", ".log"])
      file.write(log_with_empty_lines)
      file.close

      begin
        parser = described_class.new(file.path)
        records = parser.parse

        expect(records.size).to eq(2)
      ensure
        file.unlink
      end
    end

    it "raises error for non-existent file" do
      parser = described_class.new("/path/to/nonexistent/file.log")

      expect { parser.parse }.to raise_error(ArgumentError, /Log file not found/)
    end
  end
end
