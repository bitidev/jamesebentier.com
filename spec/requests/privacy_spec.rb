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

    it "mentions first-party analytics" do
      get privacy_path

      expect(response.body).to include("This site records page views in our own Postgres database")
    end

    # Regression guard (#1190): privacy.html.erb used to be a placeholder stub ("This page is
    # a placeholder") that linked back to the #1190 issue. It was rewritten into a real GDPR
    # Art. 13 policy -- assert the stub language is gone so it can't silently come back.
    it "no longer renders the retired placeholder copy" do
      get privacy_path

      expect(response.body).not_to include("This page is a placeholder")
    end

    it "no longer links back to the #1190 tracking issue" do
      get privacy_path

      expect(response.body).not_to include("#1190")
    end

    it "describes the cookieless nature of site analytics" do
      get privacy_path

      expect(response.body).to include("cookieless")
    end

    it "names the Berlin supervisory authority for data-protection complaints" do
      get privacy_path

      expect(response.body).to include("Berliner Beauftragte für Datenschutz und Informationsfreiheit")
    end

    it "describes data-subject rights under the GDPR" do
      get privacy_path

      expect(response.body).to include("right to access, rectify, or erase")
    end

    it "links the Controller section to the Impressum page" do
      get privacy_path

      expect(response.parsed_body.at_css("a[href='#{impressum_path}']")).to be_present
    end
  end
end
