# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Changelog (#1191)" do
  describe "GET /changelog" do
    it "returns a successful response" do
      get changelog_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the changelog page's terminal eyebrow and heading, not just any 200" do # rubocop:disable RSpec/MultipleExpectations
      get changelog_path

      expect(response.body).to include("cat CHANGELOG.md")
      expect(response.parsed_body.at_css("h1").text).to eq("Changelog")
    end

    it "renders the current version, sourced from db/changelog.yml via Changelog.current_version" do
      get changelog_path

      expect(response.body).to include("v#{Changelog.current_version}")
    end

    it "renders the newest release's title" do
      get changelog_path

      expect(response.body).to include(Changelog.current.title)
    end

    it "renders the newest release's date" do
      get changelog_path

      expect(response.body).to include(Changelog.current.date.strftime("%B %-d, %Y"))
    end

    it "renders at least one change line from the newest release, through the markdown pipeline" do
      get changelog_path

      # `changes` are rendered as a markdown list via BlogHelper#render_markdown -- assert
      # on the parsed text (not raw response.body) so an inline-markdown change entry
      # (e.g. a `code span`) doesn't break the match on its surrounding tag structure.
      expect(response.parsed_body.text).to include(Changelog.current.changes.first.gsub(/[`*_]/, ""))
    end

    it "lists every real release's version, not just the newest" do
      get changelog_path

      versions = Changelog.releases.map(&:version)

      expect(versions).to all(satisfy { |v| response.body.include?("v#{v}") })
    end
  end
end
