# frozen_string_literal: true

require "rails_helper"

# Increment 0 foundation coverage (R1-R2 in docs/specs/1187-modal-vim-keyboard-
# navigation.md): the mode state machine + status line, the global dispatch guard, and
# a bare `?` guide-dialog toggle. This is deliberately not exhaustive -- comprehensive
# per-route coverage (every route in R11's smoke-test list) is owned by the test agent
# in a later phase; these specs prove the foundation's core guarantees hold.
RSpec.describe "Keyboard navigation foundation", :js do
  it "reveals the NORMAL status line once JS has connected" do
    visit root_path

    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --", visible: :all)
  end

  it "opens the guide dialog on ?" do
    visit root_path

    find("body").send_keys("?")

    expect(page).to have_selector("dialog#keyboard-guide-dialog[open]")
  end

  it "closes the guide dialog on Esc" do
    visit root_path
    find("body").send_keys("?")

    find("body").send_keys(:escape)

    expect(page).to have_no_selector("dialog#keyboard-guide-dialog[open]")
  end

  it "never intercepts a keystroke while the existing theme <select> has focus" do
    visit root_path

    find("#theme-picker-select").send_keys("?")

    expect(page).to have_no_selector("dialog#keyboard-guide-dialog[open]")
  end

  it "ignores modifier-chorded keys, leaving browser/OS shortcuts unconflicted" do
    visit root_path

    find("body").send_keys([:control, "?"])

    expect(page).to have_no_selector("dialog#keyboard-guide-dialog[open]")
  end

  it "attaches exactly one document keydown listener across repeated Turbo navigations" do
    visit root_path
    %w[Blog Home Projects Home].each { |label| within("header") { click_link label } }

    # If a prior navigation left a stale listener attached, this single "?" would
    # trigger showModal() twice in the same dispatch -- Cuprite's js_errors: true
    # (spec/support/capybara.rb) turns that double-call's thrown JS exception into a
    # Ruby error, failing this example.
    find("body").send_keys("?")

    expect(page).to have_selector("dialog#keyboard-guide-dialog[open]")
  end
end
