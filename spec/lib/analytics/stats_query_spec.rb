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
end
