# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Impressum page (#1190)" do
  describe "GET /impressum" do
    it "returns a successful response" do
      get impressum_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the § 5 DDG Impressum heading, proving this is the provider-identification page" do
      get impressum_path

      expect(response.parsed_body.at_css("h2").text).to include("Angaben gemäß § 5 DDG")
    end

    it "renders the real contact email as a mailto link" do
      get impressum_path

      contact_link = response.parsed_body.at_css("a[href='mailto:jebentier@gmail.com']")

      expect(contact_link.text).to eq("jebentier@gmail.com")
    end

    it "sets the Impressum page title meta tag" do
      get impressum_path

      expect(response.parsed_body.at_css("title").text).to include("Impressum")
    end
  end
end
