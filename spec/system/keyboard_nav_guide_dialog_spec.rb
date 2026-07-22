# frozen_string_literal: true

require "rails_helper"

# Increment 6 coverage (R10 in docs/specs/1187-modal-vim-keyboard-navigation.md): the
# closeout increment that replaces Increment 0's bare `?` open/close toggle (already
# covered by spec/system/keyboard_nav_spec.rb) with the full bindings-reference content --
# every NORMAL-mode binding shipped across R3-R8, plus the COMMAND registry's v1 command
# list, rendered directly from app/javascript/keyboard_nav/commands.js's COMMAND_REGISTRY
# (renderGuideCommandList). formatCommandInvocation's own ":name"/":name (:alias)"
# formatting logic is unit-tested in commands.test.js, not re-proven here -- these specs
# prove the real DOM the dialog renders, and its accessibility semantics, against a real
# browser.
RSpec.describe "Keyboard navigation -- ? guide overlay content & a11y", :js do
  it "lists every NORMAL-mode binding shipped across R3-R8" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected

    press("?")
    dialog = find("dialog#keyboard-guide-dialog[open]")

    expect(dialog).to have_selector("kbd", text: "h")
    expect(dialog).to have_selector("kbd", text: "j")
    expect(dialog).to have_selector("kbd", text: "k")
    expect(dialog).to have_selector("kbd", text: "l")
    expect(dialog).to have_content("Scroll to top")
    expect(dialog).to have_selector("kbd", text: "G")
    expect(dialog).to have_content("home / writing / projects / lab")
    expect(dialog).to have_content("Cycle theme")
    expect(dialog).to have_content("Hint-jump")
    expect(dialog).to have_content("Enter COMMAND mode")
    expect(dialog).to have_content("Enter SEARCH mode")
    expect(dialog).to have_selector("kbd", text: "Esc")
  end

  it "renders the COMMAND registry's v1 command list directly from COMMAND_REGISTRY, including alias formatting" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected

    press("?")
    dialog = find("dialog#keyboard-guide-dialog[open]")

    expect(dialog).to have_selector("[data-keyboard-nav-target='guideCommandList'] dt", text: ":home")
    expect(dialog).to have_selector("[data-keyboard-nav-target='guideCommandList'] dt", text: ":writing")
    # :projects has one alias (:p, commands.js) -- formatCommandInvocation renders it
    # inline, proving the dialog reflects the registry's real shape, not a hand-copied
    # name-only list.
    expect(dialog).to have_selector("[data-keyboard-nav-target='guideCommandList'] dt", text: ":projects (:p)")
    expect(dialog).to have_selector("[data-keyboard-nav-target='guideCommandList'] dt", text: ":resume")
    expect(dialog).to have_selector("[data-keyboard-nav-target='guideCommandList'] dt", text: ":theme")
    expect(dialog).to have_selector("[data-keyboard-nav-target='guideCommandList'] dt", text: ":help")
    expect(dialog).to have_content("extensible")
  end

  it "labels the dialog for screen readers via aria-labelledby pointing at the visible heading" do # rubocop:disable RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected

    press("?")

    expect(page).to have_selector("dialog#keyboard-guide-dialog[aria-labelledby='keyboard-guide-dialog-title'][open]")
    expect(page).to have_selector("#keyboard-guide-dialog-title", text: "Keyboard bindings")
  end

  it "closes via the visible Close button, not just Esc, returning to NORMAL" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected

    press("?")
    expect(page).to have_selector("dialog#keyboard-guide-dialog[open]")

    within("dialog#keyboard-guide-dialog") { click_button "Close" }

    expect(page).to have_no_selector("dialog#keyboard-guide-dialog[open]")
  end

  it "renders the same command list whether opened via ? or the :help command" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected

    press(":")
    fill_in "Command", with: "help"
    find("#keyboard-command-input").send_keys(:enter)

    expect(page).to have_selector("dialog#keyboard-guide-dialog[open]")
    expect(page).to have_selector("[data-keyboard-nav-target='guideCommandList'] dt", text: ":home")
    expect(page).to have_selector("[data-keyboard-nav-target='guideCommandList'] dt", text: ":projects (:p)")
  end

  # Copilot review fix (#1226, commit 705df34): openGuideDialog now guards showModal() on
  # `.open` -- a native <dialog> throws InvalidStateError if shown modally while already
  # open. The `?` KEYDOWN path never actually reaches an open dialog (handleKeydown's own
  # guard #4 bails out first while the dialog is open), and once the dialog IS modally
  # open, a real mouse click can no longer even reach the header `?` chip underneath it
  # (the native top-layer/backdrop blocks it -- verified: a real Capybara `.click` here
  # raises Cuprite's own MouseEventFailed, "another element ... intercepted"). That's
  # exactly why the guard exists: it protects the click handler's OWN code path
  # (data-action="click->keyboard-nav#openGuideDialog") against being invoked while open
  # regardless of how -- a stale/duplicate controller instance from a Turbo-navigation
  # edge case is the realistic trigger this file's own sibling spec (keyboard_nav_spec.rb,
  # "attaches exactly one document keydown listener") already guards the keydown
  # equivalent of. Dispatching a real click event directly at the button's own DOM node
  # (bypassing hit-testing, exactly what a duplicate/stale action binding would do) is
  # what actually re-invokes openGuideDialog while open, without relying on an
  # unreproducible literal double real-world click. Cuprite's js_errors: true
  # (spec/support/capybara.rb) turns an uncaught InvalidStateError into a raised Ruby
  # error, so "no exception" needs no separate console-log assertion -- a regression here
  # fails this example outright, not silently no-ops.
  it "guards the already-open dialog against a double-open via the header ? chip's click handler (no InvalidStateError, stays open)" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
    visit root_path
    wait_for_keyboard_nav_connected

    press("?")
    expect(page).to have_selector("dialog#keyboard-guide-dialog[open]")

    page.execute_script("document.querySelector(\"button[aria-label='Keyboard shortcuts help']\").click()")

    expect(page).to have_selector("dialog#keyboard-guide-dialog[open]")
  end

  # A repeated `?` keydown while the dialog is already open never even reaches
  # openGuideDialog (handleKeydown's guard #4 bails first) -- so this proves that
  # independent, already-safe path stays a true no-op (no error, still open), distinct
  # from the click-driven regression above.
  it "stays open and raises no error on a repeated ? keypress while already open" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
    visit root_path
    wait_for_keyboard_nav_connected

    press("?")
    expect(page).to have_selector("dialog#keyboard-guide-dialog[open]")

    press("?")

    expect(page).to have_selector("dialog#keyboard-guide-dialog[open]")
  end
end
