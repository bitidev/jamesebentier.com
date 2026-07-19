# frozen_string_literal: true

require "rails_helper"

# Increment 1 coverage (R3-R4 in docs/specs/1187-modal-vim-keyboard-navigation.md):
# NORMAL-mode hjkl/gg/G scrolling and the g-prefixed page jumps via resolveNavTarget.
# Deliberately not exhaustive -- comprehensive per-binding/per-route coverage is owned
# by the test agent in a later phase; these specs prove Increment 1's acceptance
# criteria hold against a real browser.
RSpec.describe "Keyboard navigation -- NORMAL-mode navigation", :js do
  # A long, real markdown post (not the factory's default nonexistent file_path) so the
  # rendered page is tall enough to actually exercise gg/G scrolling.
  let!(:long_post) do
    create(
      :post,
      slug: "hosting-your-personal-site-on-aws-s3",
      file_path: "2024-06-13-Hosting-Your-Personal-Site-On-AWS-S3.md"
    )
  end

  # Dispatches real keydown/keyup CDP events directly, bypassing Capybara's
  # find(...).send_keys, which (per Cuprite's Node#send_keys) first performs a real
  # click on the target element to focus it -- clicking the full-height <body> element
  # scrolls its center into the viewport as a side effect, corrupting every scroll-
  # position assertion below. A bare keydown with no explicit focus target lands on
  # document.activeElement (document.body by default on a fresh page load), which is
  # exactly what the feature's document-level listener expects.
  def press(*keys)
    page.driver.browser.page.keyboard.type(*keys)
  end

  it "gg scrolls to the top of a long page" do
    visit post_path(slug: long_post.slug)
    page.evaluate_script("window.scrollTo(0, 500)")
    press("g", "g")

    expect(page.evaluate_script("window.scrollY")).to eq(0)
  end

  it "G scrolls to the bottom of a long page" do
    visit post_path(slug: long_post.slug)
    press("G")
    max_scroll = page.evaluate_script("document.documentElement.scrollHeight - window.innerHeight")

    expect(page.evaluate_script("window.scrollY")).to be_within(2).of(max_scroll)
  end

  it "g w navigates to the header nav link's actual, current writing (blog index) URL" do
    visit root_path
    press("g", "w")

    expect(page).to have_current_path(posts_path)
  end

  it "g h navigates to the header nav link's actual, current home URL" do
    visit post_path(slug: long_post.slug)
    press("g", "h")

    expect(page).to have_current_path(root_path)
  end

  it "g p navigates to the header nav link's actual, current projects URL" do
    visit root_path
    press("g", "p")

    expect(page).to have_current_path(projects_path)
  end

  it "g l is a documented no-op today (no /lab route exists yet)" do
    visit root_path
    press("g", "l")

    expect(page).to have_current_path(root_path)
  end

  it "treats an unrecognized g-sequence as a silent no-op (no error, no navigation)" do
    visit root_path
    press("g", "z")

    expect(page).to have_current_path(root_path)
  end

  it "clears the g-prefix buffer after resolving, so a following g-sequence starts fresh" do
    visit root_path
    press("g", "z", "g", "w")

    expect(page).to have_current_path(posts_path)
  end

  it "keeps j inert while the existing theme <select> has focus (no scroll)" do
    visit post_path(slug: long_post.slug)
    find("#theme-picker-select").send_keys("j")

    expect(page.evaluate_script("window.scrollY")).to eq(0)
  end

  it "keeps g-jumps inert while the existing theme <select> has focus (no navigation)" do
    visit post_path(slug: long_post.slug)
    find("#theme-picker-select").send_keys("g", "w")

    expect(page).to have_current_path(post_path(slug: long_post.slug))
  end
end
