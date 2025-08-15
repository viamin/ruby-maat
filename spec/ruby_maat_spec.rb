# frozen_string_literal: true

RSpec.describe RubyMaat do
  it "has a version number" do
    expect(RubyMaat::VERSION).not_to be_nil
    expect(RubyMaat::VERSION).to match(/\d+\.\d+\.\d+/)
  end

  describe "module loading" do
    it "loads all required modules without errors" do
      expect { RubyMaat::ChangeRecord }.not_to raise_error
      expect { RubyMaat::Dataset }.not_to raise_error
      expect { RubyMaat::CLI }.not_to raise_error
      expect { RubyMaat::App }.not_to raise_error
    end

    it "loads parser modules" do
      expect { RubyMaat::Parsers::Git2Parser }.not_to raise_error
      expect { RubyMaat::Parsers::GitParser }.not_to raise_error
      expect { RubyMaat::Parsers::SvnParser }.not_to raise_error
    end

    it "loads analysis modules" do
      expect { RubyMaat::Analysis::Authors }.not_to raise_error
      expect { RubyMaat::Analysis::LogicalCoupling }.not_to raise_error
      expect { RubyMaat::Analysis::Summary }.not_to raise_error
    end

    it "loads grouper modules" do
      expect { RubyMaat::Groupers::LayerGrouper }.not_to raise_error
      expect { RubyMaat::Groupers::TimeGrouper }.not_to raise_error
      expect { RubyMaat::Groupers::TeamMapper }.not_to raise_error
    end

    it "loads output modules" do
      expect { RubyMaat::Output::CsvOutput }.not_to raise_error
    end
  end
end
