# frozen_string_literal: true

module Analytics
  # Labels obvious bot/crawler user agents at ingest time. All traffic is still recorded;
  # `visitor_type` makes human vs bot splits easy in stats queries.
  class BotDetector
    BOT_PATTERN = /bot|crawl|spider|slurp|mediapartners|wget|curl|python-requests|httpx|headless|facebookexternalhit|bingpreview/i

    def self.bot?(user_agent)
      user_agent.present? && user_agent.match?(BOT_PATTERN)
    end

    def self.visitor_type(user_agent)
      bot?(user_agent) ? "bot" : "human"
    end
  end
end
