# frozen_string_literal: true

require "rails_helper"

# Regression guard for #1187/PR #1195 (fixed in bd4bad7): Increment 1's data-nav-target
# commit deleted the header nav's opening <ul> tag but left the orphaned closing </ul>,
# silently dropping the row-flex/right-align layout classes site-wide -- and slipped
# through green CI because the pre-existing specs only asserted data-nav-target
# presence/click behavior, never the wrapper markup itself. These specs render through
# the real layout/controller stack (application.html.erb renders the header partial on
# every route -- see line 82) so a dropped/orphaned <ul> can't pass again.
RSpec.describe "Header nav markup (1187 regression guard)" do
  describe "GET / -- header nav <ul> wrapper" do
    it "renders exactly one <ul> in the header" do
      get root_path
      header = response.parsed_body.at_css("header")

      expect(header.css("ul").size).to eq(1)
    end

    it "wraps the Home/Writing/Projects/Resume nav <li> items inside that single <ul>" do
      get root_path
      nav_ul = response.parsed_body.at_css("header ul")

      expect(nav_ul.css("li").size).to be >= 4
    end

    it "wraps the Home/Writing/Projects/Resume nav links inside that single <ul>" do
      get root_path
      nav_ul = response.parsed_body.at_css("header ul")
      nav_texts = nav_ul.css("li a").map(&:text)

      expect(nav_texts).to include("Home", "Writing", "Projects", "Resume")
    end

    it "carries the load-bearing right-align/row-flex layout classes on that <ul> (bd4bad7)" do
      get root_path
      nav_ul = response.parsed_body.at_css("header ul")

      expect(nav_ul.classes).to include(
        "flex", "flex-row", "ml-auto", "justify-end", "list-none", "content-center", "items-center", "my-auto"
      )
    end
  end
end
