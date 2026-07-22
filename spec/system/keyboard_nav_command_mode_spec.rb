# frozen_string_literal: true

require "rails_helper"

# Increment 3 coverage (R6 in docs/specs/1187-modal-vim-keyboard-navigation.md): COMMAND
# mode -- `:` entry, the terminal-style input, the v1 command set (home/writing/
# projects/resume/theme/help), and the not-found/focus-restore semantics. Deliberately
# not exhaustive -- comprehensive per-command/per-route coverage is owned by the test
# agent in a later phase; these specs prove Increment 3's acceptance criteria hold
# against a real browser. parseCommand/rankCommands' own ranking/unknown-input behavior
# is unit-tested in app/javascript/keyboard_nav/commands.test.js, not re-proven here.
#
# Every example below calls wait_for_keyboard_nav_connected (spec/support/
# keyboard_nav_helpers.rb) right after `visit`, before any key dispatch, and uses the
# raw-CDP `press` helper (also from that shared file) for body-level keydowns -- see
# that file's comments for the CI-only connect race and the body-click side effect both
# guard against. Once focus has moved into the command input itself, typing into it uses
# ordinary Capybara `send_keys`/`fill_in` -- there is no ambiguous full-height-body-click
# concern for a small, on-screen, already-focused <input>.
RSpec.describe "Keyboard navigation -- COMMAND mode (:)", :js do
  it "opens the bar, moves focus into it, and switches the status line to COMMAND" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    expect(page).to have_no_selector("#keyboard-command-bar")

    press(":")

    expect(page).to have_selector("#keyboard-status-line", text: "-- COMMAND --")
    expect(page).to have_selector("#keyboard-command-bar")
    # A retrying selector-based check, not a one-shot evaluate_script(document.activeElement)
    # -- focus() is called synchronously inside the same keydown handler that reveals the
    # bar, but Capybara/Ruby can observe the DOM a tick before the browser has finished
    # settling that focus move, so this must be allowed to retry like every other
    # assertion here.
    expect(page).to have_selector("#keyboard-command-input:focus")
  end

  it "navigates to writing via :writing, exactly the header nav link's current URL" do # rubocop:disable RSpec/ExampleLength
    visit root_path
    wait_for_keyboard_nav_connected
    press(":")
    fill_in "Command", with: "writing"
    find("#keyboard-command-input").send_keys(:enter)

    expect(page).to have_current_path(posts_path)
  end

  it "navigates to projects via :projects" do # rubocop:disable RSpec/ExampleLength
    visit root_path
    wait_for_keyboard_nav_connected
    press(":")
    fill_in "Command", with: "projects"
    find("#keyboard-command-input").send_keys(:enter)

    expect(page).to have_current_path(projects_path)
  end

  it "navigates to resume via :resume" do # rubocop:disable RSpec/ExampleLength
    visit root_path
    wait_for_keyboard_nav_connected
    press(":")
    fill_in "Command", with: "resume"
    find("#keyboard-command-input").send_keys(:enter)

    expect(page).to have_current_path(resume_path)
  end

  it "navigates to home via :home, from a non-home page" do # rubocop:disable RSpec/ExampleLength
    visit projects_path
    wait_for_keyboard_nav_connected
    press(":")
    fill_in "Command", with: "home"
    find("#keyboard-command-input").send_keys(:enter)

    expect(page).to have_current_path(root_path)
  end

  # Proves R6's ":theme <name> sets the theme identically to the t path" claim -- same
  # observable outcome (visible <select> value + document theme) the Increment 2 tests
  # assert for `t` itself, not just that some theme changed.
  it "sets the theme via :theme <name> exactly as t does" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    press(":")
    fill_in "Command", with: "theme dracula"
    find("#keyboard-command-input").send_keys(:enter)

    expect(page).to have_field("theme-picker-select", with: "dracula")
    expect(page.evaluate_script("document.documentElement.dataset.theme")).to eq("dracula")
  end

  it "returns to NORMAL and clears the bar after a successful command" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    press(":")
    fill_in "Command", with: "theme nord"
    find("#keyboard-command-input").send_keys(:enter)

    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")
    expect(page).to have_no_selector("#keyboard-command-bar")
  end

  # Esc restoring focus to a real prior element (not document.body) -- exercised against
  # a header nav link, which is focusable but not an "editable target," so entering
  # COMMAND mode from it is itself a meaningful case (unlike the native <select>, which
  # the isEditableTarget guard would keep `:` from ever reaching).
  it "restores focus, on Esc, to whatever had it before entry -- not assumed to be document.body" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    page.evaluate_script('document.querySelector("[data-nav-target=\"projects\"]").focus()')

    press(":")
    expect(page).to have_selector("#keyboard-command-bar")

    press(:escape)

    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")
    expect(page).to have_selector("[data-nav-target='projects']:focus")
  end

  # Enter's focus-restore, proven with a non-navigating command (:theme) since a
  # navigating command (:home et al.) replaces <body> entirely on the new page, making
  # "restored focus" unobservable/moot on the page that follows.
  it "restores focus, on Enter, to whatever had it before entry" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    page.evaluate_script('document.querySelector("[data-nav-target=\"projects\"]").focus()')

    press(":")
    fill_in "Command", with: "theme gruvbox"
    find("#keyboard-command-input").send_keys(:enter)

    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")
    expect(page).to have_selector("[data-nav-target='projects']:focus")
  end

  it "leaves the bar open with a visible not-found state for an unrecognized command name, with no navigation" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    press(":")
    fill_in "Command", with: "bogus"
    find("#keyboard-command-input").send_keys(:enter)

    expect(page).to have_current_path(root_path)
    expect(page).to have_selector("#keyboard-status-line", text: "-- COMMAND --")
    expect(page).to have_selector("#keyboard-command-bar")
    expect(page).to have_selector("[data-keyboard-nav-target='commandFeedback']", text: "bogus: command not found")
  end

  # An unrecognized *theme* name is the same "not found" state (spec: run() returning
  # false is treated identically to an unknown command name), not a silent no-op and not
  # a third, undocumented failure mode.
  it "treats :theme <unrecognized-name> as not-found, without changing the current theme" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    press(":")
    fill_in "Command", with: "theme not-a-real-theme"
    find("#keyboard-command-input").send_keys(:enter)

    # gruvbox is the site default, so an unchanged first-time visitor stays on it.
    expect(page).to have_field("theme-picker-select", with: "gruvbox")
    expect(page).to have_selector("[data-keyboard-nav-target='commandFeedback']", text: "command not found")
  end

  it "opens the same ? guide dialog via :help" do # rubocop:disable RSpec/ExampleLength
    visit root_path
    wait_for_keyboard_nav_connected
    press(":")
    fill_in "Command", with: "help"
    find("#keyboard-command-input").send_keys(:enter)

    expect(page).to have_selector("dialog#keyboard-guide-dialog[open]")
  end

  # :help opens the guide via showModal() after COMMAND mode exits; Esc-closing the
  # dialog must restore the focus target from before `:` was pressed, not the hidden
  # command input (issue #1196).
  it "returns focus to the pre-COMMAND target after Escape-closing the :help guide dialog" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    page.evaluate_script('document.querySelector("[data-nav-target=\"projects\"]").focus()')

    press(":")
    fill_in "Command", with: "help"
    find("#keyboard-command-input").send_keys(:enter)

    expect(page).to have_selector("dialog#keyboard-guide-dialog[open]")

    press(:escape)

    expect(page).to have_no_selector("dialog#keyboard-guide-dialog[open]")
    expect(page).to have_selector("[data-nav-target='projects']:focus")
  end

  it "live-filters matching command names into the feedback row as the visitor types" do
    visit root_path
    wait_for_keyboard_nav_connected
    press(":")
    fill_in "Command", with: "pro"

    expect(page).to have_selector("[data-keyboard-nav-target='commandFeedback']", text: ":projects")
  end

  it "keeps : inert while the existing theme <select> has focus (no bar, no mode change)" do # rubocop:disable RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected

    find("#theme-picker-select").send_keys(":")

    expect(page).to have_no_selector("#keyboard-command-bar")
    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")
  end
end
