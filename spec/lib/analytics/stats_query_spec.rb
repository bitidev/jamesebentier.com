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
  # a zero-filled, oldest -> newest series over the same PageView population :total counts
  # (no visitor_type filter), tiled into 24h buckets measured FROM `since` (commit f07ec27),
  # not calendar dates -- calendar-date bucketing silently dropped any view recorded in the
  # `since`-day sliver (after `since`'s own time-of-day but still "yesterday" on the
  # calendar), breaking `daily_view_counts.sum == fetch(:total)` for any non-midnight "now".
  # Timecop freezes "now" so `window_start`/`bucket_count`'s `Time.current` are deterministic
  # -- the same technique this file's own `.fetch` context already relies on implicitly via
  # `n.days.ago`, made explicit here since bucketing is sensitive to exactly where "now" falls.
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

    it "attributes each page view to its own 24h bucket, tiled from `since` (not calendar midnight)" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      Timecop.freeze(Time.zone.parse("2026-07-21 12:00:00")) do
        since = described_class.window_start("7d")
        create(:page_view, recorded_at: since + 1.day - 1.second)
        create(:page_view, recorded_at: since + 1.day)

        counts = described_class.daily_view_counts(window: "7d")

        expect(counts[0]).to eq(1)
        expect(counts[1]).to eq(1)
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

    # Regression: commit f07ec27 fixed daily_view_counts' rolling-window off-by-one. The old
    # calendar-date implementation (`day_range`) always excluded the calendar date `since`
    # itself falls on, even though `since` includes every moment on that date from its own
    # timestamp onward -- so a page view landing in that "since-day sliver" was counted in
    # fetch's :total (recorded_at >= since) but silently dropped from daily_view_counts. That
    # only manifests when "now" is NOT exactly midnight (i.e. essentially always in
    # production), so this freezes a real, non-midnight time and plants a view exactly one
    # hour into the window -- the precise row the old implementation lost.
    it "sums to the total even when a view falls in the since-day sliver (boundary regression, f07ec27)" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      Timecop.freeze(Time.utc(2026, 7, 21, 15, 0, 0)) do
        since = described_class.window_start("7d")
        create(:page_view, recorded_at: since + 1.hour) # the sliver row the old code dropped
        create(:page_view, recorded_at: since + 3.days)
        create(:page_view, recorded_at: 1.hour.ago)
        create(:page_view, recorded_at: since - 1.hour) # outside the window -- must not count

        total = described_class.fetch(metric: "views", window: "7d")[:total]
        series = described_class.daily_view_counts(window: "7d")

        expect(series.sum).to eq(total)
        expect(series.first).to be >= 1
      end
    end
  end
end
