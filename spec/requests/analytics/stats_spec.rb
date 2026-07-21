# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /analytics/stats.json" do
  before do
    create(:page_view, path: "/writing/post-a", visitor_type: "human", recorded_at: 1.day.ago)
    create(:page_view, :bot, path: "/writing/post-a", recorded_at: 1.day.ago)
  end

  it "returns aggregate views for a valid query" do
    get analytics_stats_path, params: { q: "views --last 7d" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(
      "metric" => "views",
      "total" => 2,
      "human" => 1,
      "bot" => 1
    )
  end

  it "rejects an invalid query" do
    get analytics_stats_path, params: { q: "bogus" }

    expect(response).to have_http_status(:bad_request)
  end
end
