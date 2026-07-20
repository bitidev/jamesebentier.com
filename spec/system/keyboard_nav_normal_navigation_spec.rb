# frozen_string_literal: true

require "rails_helper"

# Increment 1 coverage (R3-R4 in docs/specs/1187-modal-vim-keyboard-navigation.md):
# NORMAL-mode hjkl/gg/G scrolling and the g-prefixed page jumps via resolveNavTarget.
# Deliberately not exhaustive -- comprehensive per-binding/per-route coverage is owned
# by the test agent in a later phase; these specs prove Increment 1's acceptance
# criteria hold against a real browser.
#
# Every example below calls wait_for_keyboard_nav_connected (spec/support/
# keyboard_nav_helpers.rb) right after `visit`, before any scroll setup or key
# dispatch -- see that file's comments for the CI-only connect race this guards
# against. `press` (also from that shared file) dispatches raw CDP keydown/keyup
# events, bypassing Capybara's find(...).send_keys, which (per Cuprite's
# Page#send_keys) first performs a real click on the target element to focus it --
# clicking the full-height <body> element scrolls its center into the viewport as a
# side effect, corrupting every scroll-position assertion below. A bare keydown with
# no explicit focus target lands on document.activeElement (document.body by default
# on a fresh page load), exactly what the feature's document-level listener expects.
RSpec.describe "Keyboard navigation -- NORMAL-mode navigation", :js do
  # Long markdown fixture for scroll/hint-jump coverage (distinct from the factory default).
  # The rendered page must be tall enough to exercise gg/G scrolling.
  let!(:long_post) do
    create(
      :post,
      slug: "hosting-your-personal-site-on-aws-s3",
      file_path: "2024-06-13-Hosting-Your-Personal-Site-On-AWS-S3.md"
    )
  end

  it "gg scrolls to the top of a long page" do
    visit post_path(slug: long_post.slug)
    wait_for_keyboard_nav_connected
    page.evaluate_script("window.scrollTo(0, 500)")
    press("g", "g")

    expect(page.evaluate_script("window.scrollY")).to eq(0)
  end

  it "G scrolls to the bottom of a long page" do
    visit post_path(slug: long_post.slug)
    wait_for_keyboard_nav_connected
    press("G")
    max_scroll = page.evaluate_script("document.documentElement.scrollHeight - window.innerHeight")

    expect(page.evaluate_script("window.scrollY")).to be_within(2).of(max_scroll)
  end

  it "g w navigates to the header nav link's actual, current writing (blog index) URL" do
    visit root_path
    wait_for_keyboard_nav_connected
    press("g", "w")

    expect(page).to have_current_path(posts_path)
  end

  it "g h navigates to the header nav link's actual, current home URL" do
    visit post_path(slug: long_post.slug)
    wait_for_keyboard_nav_connected
    press("g", "h")

    expect(page).to have_current_path(root_path)
  end

  it "g p navigates to the header nav link's actual, current projects URL" do
    visit root_path
    wait_for_keyboard_nav_connected
    press("g", "p")

    expect(page).to have_current_path(projects_path)
  end

  it "g l is a documented no-op today (no /lab route exists yet)" do
    visit root_path
    wait_for_keyboard_nav_connected
    press("g", "l")

    expect(page).to have_current_path(root_path)
  end

  it "treats an unrecognized g-sequence as a silent no-op (no error, no navigation)" do
    visit root_path
    wait_for_keyboard_nav_connected
    press("g", "z")

    expect(page).to have_current_path(root_path)
  end

  it "clears the g-prefix buffer after resolving, so a following g-sequence starts fresh" do
    visit root_path
    wait_for_keyboard_nav_connected
    press("g", "z", "g", "w")

    expect(page).to have_current_path(posts_path)
  end

  it "keeps j inert while the existing theme <select> has focus (no scroll)" do
    visit post_path(slug: long_post.slug)
    wait_for_keyboard_nav_connected
    find("#theme-picker-select").send_keys("j")

    expect(page.evaluate_script("window.scrollY")).to eq(0)
  end

  it "keeps g-jumps inert while the existing theme <select> has focus (no navigation)" do
    visit post_path(slug: long_post.slug)
    wait_for_keyboard_nav_connected
    find("#theme-picker-select").send_keys("g", "w")

    expect(page).to have_current_path(post_path(slug: long_post.slug))
  end
end
