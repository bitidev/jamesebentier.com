# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::BotDetector do
  describe ".visitor_type" do
    it "labels common crawler user agents as bot" do
      expect(described_class.visitor_type("Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)")).to eq("bot")
    end

    it "labels normal browsers as human" do
      expect(described_class.visitor_type("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/537.36 Chrome/126.0.0.0 Safari/537.36")).to eq("human")
    end

    it "labels a blank user agent as human" do
      expect(described_class.visitor_type(nil)).to eq("human")
    end
  end
end
