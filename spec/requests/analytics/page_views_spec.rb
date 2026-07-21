# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /analytics/page_views" do
  it "records a page view from the Turbo beacon" do
    expect do
      post analytics_page_views_path, params: { path: "/writing/foo", referrer: "https://example.com/" }, as: :json
    end.to change(PageView, :count).by(1)

    expect(response).to have_http_status(:no_content)
    expect(PageView.last.path).to eq("/writing/foo")
  end
end
