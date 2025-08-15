# frozen_string_literal: true

module RubyMaat
  module Analysis
    # Identity analysis - debugging analysis that just returns raw data
    class Identity < BaseAnalysis
      def analyze(dataset, _options = {})
        dataset.to_df
      end
    end
  end
end
