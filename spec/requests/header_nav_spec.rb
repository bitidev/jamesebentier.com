# frozen_string_literal: true

require "rails_helper"

# Regression guard for #1187/PR #1195 (fixed in bd4bad7): Increment 1's data-nav-target
# commit deleted the header nav's opening <ul> tag but left the orphaned closing </ul>,
# silently dropping the row-flex/right-align layout classes site-wide -- and slipped
# through green CI because the pre-existing specs only asserted data-nav-target
# presence/click behavior, never the wrapper markup itself.
#
# Terminal-identity redesign (#1226) rewrote the header's own internal markup: there is no
# longer a <ul>/<li> nav list at all (app/views/layouts/components/_header.html.erb wraps
# its links directly in a <nav>), and the separate "Home" nav item is gone -- Home's own
# data-nav-target now lives on the "❯ james@ebentier" logo link instead of a nav <li>. The
# specific historical <ul>/<li> bug this file guards against can no longer recur (there's
# no <ul> to orphan), so these specs are rewritten around the regression's real underlying
# concern -- the nav's real Rails-URL wiring and its row-flex/right-align layout -- rather
# than markup that no longer exists. These still render through the real layout/controller
# stack (application.html.erb renders the header partial on every route).
RSpec.describe "Header nav markup (1187 regression guard)" do
  describe "GET / -- header nav data-nav-target wiring" do
    it "resolves all five data-nav-target anchors to their real Rails URLs" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      get root_path
      header = response.parsed_body.at_css("header")

      expect(header.at_css("a[data-nav-target='home']")["href"]).to eq(root_url)
      expect(header.at_css("a[data-nav-target='writing']")["href"]).to eq(posts_url)
      expect(header.at_css("a[data-nav-target='projects']")["href"]).to eq(projects_url)
      expect(header.at_css("a[data-nav-target='about']")["href"]).to eq(about_path)
      expect(header.at_css("a[data-nav-target='resume']")["href"]).to eq(resume_path)
    end

    it "renders exactly one <nav> in the header, wrapping the four non-home nav links" do # rubocop:disable RSpec/MultipleExpectations
      get root_path
      header = response.parsed_body.at_css("header")

      expect(header.css("nav").size).to eq(1)
      nav_targets = header.at_css("nav").css("a").pluck("data-nav-target")

      expect(nav_targets).to include("writing", "projects", "about", "resume")
    end

    it "carries the load-bearing right-align/row-flex layout classes on the nav wrapper (bd4bad7)" do
      get root_path
      nav = response.parsed_body.at_css("header nav")

      expect(nav.classes).to include("ml-auto", "flex", "items-center")
    end
  end
end
