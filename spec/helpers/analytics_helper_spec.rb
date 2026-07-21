# frozen_string_literal: true

require 'rails_helper'

# app/helpers/analytics_helper.rb -- maps Analytics::StatsQuery.daily_view_counts' zero-
# filled daily series to the Home stats block's sparkline glyphs (terminal-identity redesign
# #1226 PR review fix: the sparkline is now a real, data-driven render, not a hardcoded
# literal like "▁▂▂▃▅▃▇").
RSpec.describe AnalyticsHelper do
  describe "#sparkline" do
    it "renders an all-zero series (brand-new DB, no page views yet) as a flat line of the lowest glyph" do
      expect(helper.sparkline([0, 0, 0, 0, 0, 0, 0])).to eq("▁▁▁▁▁▁▁")
    end

    it "scales a known series to the expected glyphs, relative to the series max" do
      expect(helper.sparkline([0, 1, 2, 4])).to eq("▁▃▅█")
    end

    it "renders a single-element series as the top glyph when it's also the max" do
      expect(helper.sparkline([5])).to eq("█")
    end

    it "returns one glyph per input count -- output length always equals input length" do
      counts = [3, 0, 7, 2, 9, 1, 4]

      expect(helper.sparkline(counts).length).to eq(counts.length)
    end

    it "returns an empty string for an empty series rather than raising" do
      expect(helper.sparkline([])).to eq("")
    end
  end
end
