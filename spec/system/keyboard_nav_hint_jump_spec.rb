# frozen_string_literal: true

require "rails_helper"

# Increment 5 coverage (R8 in docs/specs/1187-modal-vim-keyboard-navigation.md): `f`
# hint-jump -- labeling every on-screen <a href> in DOM/tab order, typed-label
# activation via a real click (Turbo-driven navigation, exactly like a mouse click), and
# Esc/scroll/invalid-input cancellation with zero leftover badge/focus/tabindex state.
# Deliberately not exhaustive -- comprehensive per-route coverage is owned by the test
# agent in a later phase; these specs prove Increment 5's acceptance criteria hold
# against a real browser. assignHintLabels' own single-to-two-character boundary logic
# is unit-tested in app/javascript/keyboard_nav/hints.test.js, not re-proven here.
#
# The header's "Home" link (data-nav-target="home") is the first thing
# application.html.erb's <body> renders on every route (_header.html.erb, before any
# main content) -- it is therefore *always* the first <a href> assignHintLabels sees, in
# DOM order. That makes its hint label deterministically the alphabet's first letter
# ("a", app/javascript/keyboard_nav/hints.js's HINT_ALPHABET) without this spec needing
# to hardcode or predict the total on-screen link count on any given route.
#
# target="_blank"/rel/Turbo-handling fidelity is not separately re-tested here: hint-
# jump's activation path is `.click()` on the real anchor -- the exact same call
# g-jumps (navigateTo, spec/system/keyboard_nav_normal_navigation_spec.rb) and SEARCH's
# Enter (commitSearch, spec/system/keyboard_nav_search_spec.rb) already exercise. There
# is one activation code path in this feature, not a hint-jump-specific one, so there is
# nothing hint-jump-specific left to prove about it here.
RSpec.describe "Keyboard navigation -- f hint-jump", :js do
  let!(:long_post) do
    create(
      :post,
      slug: "hosting-your-personal-site-on-aws-s3",
      file_path: "2024-06-13-Hosting-Your-Personal-Site-On-AWS-S3.md"
    )
  end

  it "labels on-screen links, and typing the Home link's hint label activates it exactly like a click" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit post_path(slug: long_post.slug)
    wait_for_keyboard_nav_connected

    press("f")

    expect(page).to have_selector("#keyboard-status-line", text: "(HINT)")
    expect(page).to have_selector("[data-hint-label='a']")

    press("a")

    expect(page).to have_current_path(root_path)
    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")
    expect(page).to have_no_selector("[data-hint-label]")
  end

  it "Esc cancels hint-jump: removes every badge and leaves no stray focus/tabindex behind" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected

    press("f")
    expect(page).to have_selector("[data-hint-label]", minimum: 1)

    press(:escape)

    expect(page).to have_no_selector("[data-hint-label]")
    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")
    expect(page.evaluate_script("document.body.dataset.keyboardHint")).to eq("false")
    expect(page.evaluate_script("document.activeElement.tagName")).to eq("BODY")
  end

  it "cancels hint-jump on the first scroll event, removing every badge" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit post_path(slug: long_post.slug)
    wait_for_keyboard_nav_connected

    press("f")
    expect(page).to have_selector("[data-hint-label]", minimum: 1)

    page.evaluate_script("window.scrollBy(0, 40)")

    expect(page).to have_no_selector("[data-hint-label]")
    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")
  end

  it "cancels hint-jump on a keystroke matching no rendered hint label (invalid input)" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected

    press("f")
    used_labels = page.evaluate_script(
      "Array.from(document.querySelectorAll('[data-hint-label]')).map((el) => el.dataset.hintLabel)"
    )
    unused_letter = %w[a s d f g h j k q w e r t y u p z x c v b n m].find { |letter| used_labels.exclude?(letter) }
    raise "test setup assumption broken: every hint letter is already in use on this route" unless unused_letter

    press(unused_letter)

    expect(page).to have_no_selector("[data-hint-label]")
    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")
    expect(page).to have_current_path(root_path)
  end

  it "is a no-op when there are no on-screen links to hint" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    page.evaluate_script("document.querySelectorAll('a[href]').forEach((a) => { a.style.display = 'none' })")

    press("f")

    expect(page).to have_no_selector("[data-hint-label]")
    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")
  end

  it "keeps f inert while the existing theme <select> has focus (no overlay, no HINT qualifier)" do # rubocop:disable RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected

    find("#theme-picker-select").send_keys("f")

    expect(page).to have_no_selector("[data-hint-label]")
    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")
  end
end
