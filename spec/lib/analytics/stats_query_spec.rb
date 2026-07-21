# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::StatsQuery do
  describe ".parse_metric_and_args" do
    it "parses views with a default window" do
      expect(described_class.parse_metric_and_args("views")).to eq({ metric: "views", window: "7d" })
    end

    it "parses top posts with an explicit window" do
      expect(described_class.parse_metric_and_args("top posts --last 30d")).to eq({ metric: "top_posts", window: "30d" })
    end

    it "returns nil for an unknown metric" do
      expect(described_class.parse_metric_and_args("bogus")).to be_nil
    end
  end

  describe ".fetch" do
    before do
      create(:page_view, path: "/writing/post-a", visitor_type: "human", recorded_at: 1.day.ago)
      create(:page_view, :bot, path: "/writing/post-a", recorded_at: 1.day.ago)
      create(:page_view, path: "/writing/post-b", visitor_type: "human", recorded_at: 2.days.ago)
      create(:page_view, path: "/", referrer: "news.ycombinator.com/item", recorded_at: 1.day.ago)
    end

    it "returns the total view count" do
      payload = described_class.fetch(metric: "views", window: "7d")

      expect(payload[:total]).to eq(4)
    end

    it "returns the human view count" do
      payload = described_class.fetch(metric: "views", window: "7d")

      expect(payload[:human]).to eq(3)
    end

    it "returns the bot view count" do
      payload = described_class.fetch(metric: "views", window: "7d")

      expect(payload[:bot]).to eq(1)
    end

    it "returns top writing paths" do
      payload = described_class.fetch(metric: "top_posts", window: "7d")

      expect(payload[:rows].first).to eq({ path: "/writing/post-a", count: 2 })
    end

    it "returns top referrers" do
      payload = described_class.fetch(metric: "referrers", window: "7d")

      expect(payload[:rows].first).to eq({ referrer: "news.ycombinator.com/item", count: 1 })
    end
  end

  # .daily_view_counts backs the Home "stats" block's sparkline (#1226 PR review fix) --
  # a zero-filled, oldest -> newest daily series over the same PageView population :total
  # counts (no visitor_type filter). Timecop freezes "now" so `window_start`/day_range's
  # `Time.current` are deterministic -- the same technique this file's own `.fetch` context
  # already relies on implicitly via `n.days.ago`, made explicit here since day-bucketing
  # is sensitive to exactly where "now" falls.
  describe ".daily_view_counts" do
    it "returns exactly 7 entries for a 7d window" do
      Timecop.freeze(Time.zone.parse("2026-07-21 12:00:00")) do
        expect(described_class.daily_view_counts(window: "7d").length).to eq(7)
      end
    end

    it "returns exactly 1 entry for a 24h window" do
      Timecop.freeze(Time.zone.parse("2026-07-21 12:00:00")) do
        expect(described_class.daily_view_counts(window: "24h").length).to eq(1)
      end
    end

    it "zero-fills days with no page views" do # rubocop:disable RSpec/ExampleLength
      Timecop.freeze(Time.zone.parse("2026-07-21 12:00:00")) do
        create(:page_view, recorded_at: Time.zone.parse("2026-07-15 09:00:00"))
        create(:page_view, recorded_at: Time.zone.parse("2026-07-21 09:00:00"))

        counts = described_class.daily_view_counts(window: "7d")

        expect(counts).to eq([1, 0, 0, 0, 0, 0, 1])
      end
    end

    it "attributes each page view to its own calendar day, not the adjacent one across a midnight boundary" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      Timecop.freeze(Time.zone.parse("2026-07-21 12:00:00")) do
        create(:page_view, recorded_at: Time.zone.parse("2026-07-17 23:59:59"))
        create(:page_view, recorded_at: Time.zone.parse("2026-07-18 00:00:01"))

        counts = described_class.daily_view_counts(window: "7d")

        # day_range for this frozen "now" is 07-15..07-21 -- 07-17 is index 2, 07-18 index 3.
        expect(counts[2]).to eq(1)
        expect(counts[3]).to eq(1)
      end
    end

    it "sums to the same total that .fetch(metric: 'views') reports for the same window" do # rubocop:disable RSpec/ExampleLength
      Timecop.freeze(Time.zone.parse("2026-07-21 12:00:00")) do
        create(:page_view, recorded_at: Time.zone.parse("2026-07-15 08:00:00"))
        create(:page_view, :bot, recorded_at: Time.zone.parse("2026-07-15 10:00:00"))
        create(:page_view, recorded_at: Time.zone.parse("2026-07-18 15:00:00"))
        create(:page_view, recorded_at: Time.zone.parse("2026-07-21 08:00:00"))

        total = described_class.fetch(metric: "views", window: "7d")[:total]
        daily_sum = described_class.daily_view_counts(window: "7d").sum

        expect(daily_sum).to eq(total)
      end
    end
  end
end
