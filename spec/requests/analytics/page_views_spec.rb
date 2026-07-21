# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /analytics/page_views" do
  it "creates a page view from the Turbo beacon payload" do
    expect do
      post analytics_page_views_path, params: { path: "/writing/foo", referrer: "https://example.com/" }, as: :json
    end.to change(PageView, :count).by(1)
  end

  it "responds with no content" do
    post analytics_page_views_path, params: { path: "/writing/foo", referrer: "https://example.com/" }, as: :json

    expect(response).to have_http_status(:no_content)
  end

  it "stores the posted path on the new page view" do
    post analytics_page_views_path, params: { path: "/writing/foo", referrer: "https://example.com/" }, as: :json

    expect(PageView.last.path).to eq("/writing/foo")
  end
end
