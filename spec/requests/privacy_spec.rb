# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Privacy page" do
  describe "GET /privacy" do
    it "returns a successful response" do
      get privacy_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the Privacy Policy heading" do
      get privacy_path

      expect(response.parsed_body.at_css("h1").text).to include("Privacy Policy")
    end

    it "mentions newsletter data collection" do
      get privacy_path

      expect(response.body).to include("newsletter")
    end
  end
end
