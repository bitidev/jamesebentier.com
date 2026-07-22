# frozen_string_literal: true

require "rails_helper"

# Increment 2 coverage (R5 in docs/specs/1187-modal-vim-keyboard-navigation.md): the
# NORMAL-mode `t` theme cycle, reusing the existing P1.1 theme-picker <select>/
# localStorage mechanism as its single source of truth -- not a parallel theme-apply/
# persist path. Deliberately not exhaustive -- comprehensive per-theme/per-route
# coverage is owned by the test agent in a later phase; these specs prove Increment 2's
# acceptance criteria hold against a real browser.
#
# Every example below calls wait_for_keyboard_nav_connected (spec/support/
# keyboard_nav_helpers.rb) right after `visit`, before any key dispatch, and uses the
# raw-CDP `press` helper (also from that shared file) rather than
# find(...).send_keys -- see that file's comments for the CI-only connect race and the
# body-click side effect both guard against.
RSpec.describe "Keyboard navigation -- theme cycle (t)", :js do
  # One coherent flow (confirm the starting theme, then step through the rest of the
  # order) -- splitting the starting-state check into its own example would just
  # duplicate the visit/connect setup without proving anything new.
  it "advances the visible <select> value through the full 6-theme order on repeated t" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    # gruvbox is the site default (application.tailwind.css), so a first-time visitor with
    # no stored preference starts here rather than at the head of THEME_CYCLE_ORDER.
    expect(page).to have_field("theme-picker-select", with: "gruvbox")

    # The rest of the cycle from gruvbox, wrapping catppuccin -> light -> ... -> nord.
    %w[catppuccin light dark dracula nord].each do |expected_theme|
      press("t")

      expect(page).to have_field("theme-picker-select", with: expected_theme)
    end
  end

  # The wrap precondition (one press from the gruvbox default lands on catppuccin, the
  # last theme in THEME_CYCLE_ORDER) matters here -- this example proves the next press
  # wraps to light, which requires first confirming it actually reached the end.
  it "wraps from catppuccin back to light" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    press("t")
    expect(page).to have_field("theme-picker-select", with: "catppuccin")

    press("t")

    expect(page).to have_field("theme-picker-select", with: "light")
  end

  # Proves R5's "identical outcome to a manual dropdown change" claim, not just that
  # some theme changed -- both the <select>'s value and the applied
  # documentElement.dataset.theme must move together.
  it "applies the new theme to the document exactly as a manual dropdown change would" do # rubocop:disable RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected

    # One press from the gruvbox default advances to catppuccin (the next entry after
    # gruvbox in THEME_CYCLE_ORDER).
    press("t")

    expect(page).to have_field("theme-picker-select", with: "catppuccin")
    expect(page.evaluate_script("document.documentElement.dataset.theme")).to eq("catppuccin")
  end

  # Both the visible <select> and the underlying localStorage value matter here --
  # theme-picker#change (the single code path t drives) writes both together.
  it "persists the new theme to localStorage under the same key the picker uses" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected

    # From the gruvbox default: press 1 -> catppuccin, press 2 wraps to light.
    press("t")
    press("t")

    expect(page).to have_field("theme-picker-select", with: "light")
    expect(page.evaluate_script("window.localStorage.getItem('theme')")).to eq("light")
  end

  # The pre-reload state matters here -- this example proves the choice survives a
  # fresh page load (the render-blocking inline script reapplying the persisted
  # value), which requires first confirming t actually set it.
  it "keeps the picker in sync after t: reloading the page reflects the t-driven choice, matching a manual selection" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected

    press("t")
    expect(page).to have_field("theme-picker-select", with: "catppuccin")

    visit root_path
    wait_for_keyboard_nav_connected

    expect(page).to have_field("theme-picker-select", with: "catppuccin")
    expect(page.evaluate_script("document.documentElement.dataset.theme")).to eq("catppuccin")
  end

  it "keeps t inert while the existing theme <select> has focus (no cycle-on-typeahead)" do
    visit root_path
    wait_for_keyboard_nav_connected

    find("#theme-picker-select").send_keys("t")

    expect(page).to have_field("theme-picker-select", with: "gruvbox")
  end
end
