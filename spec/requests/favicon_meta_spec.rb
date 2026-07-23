# frozen_string_literal: true

require "rails_helper"

# Two consumer-facing wiring points for the #1235 terminal-mark favicon refresh, beyond
# the generated artifacts themselves (see spec/lib/favicon/generator_spec.rb): the
# layout's apple-touch-icon link tag (see spec/requests/structured_data_spec.rb for the
# established `get` + `response.parsed_body` request-spec pattern this mirrors), and the
# PWA manifest's theme_color/background_color.
RSpec.describe "Favicon and app-icon meta (#1235)" do
  it "renders an apple-touch-icon link pointing at /apple-touch-icon.png" do
    get root_path

    link = response.parsed_body.at_css("link[rel='apple-touch-icon']")

    expect(link&.[]("href")).to eq("/apple-touch-icon.png")
  end

  it "public/manifest.json parses and matches the terminal-mark theme/background color" do
    manifest = JSON.parse(Rails.public_path.join("manifest.json").read)

    expect([manifest["theme_color"], manifest["background_color"]]).to eq(["#0d1117", "#0d1117"])
  end
end
