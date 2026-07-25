# frozen_string_literal: true

require "rails_helper"

# Increment 0 foundation coverage (R1-R2 in docs/specs/1187-modal-vim-keyboard-
# navigation.md): the mode state machine + status line, the global dispatch guard, and
# a bare `?` guide-dialog toggle. This is deliberately not exhaustive -- comprehensive
# per-route coverage (every route in R11's smoke-test list) is owned by the test agent
# in a later phase; these specs prove the foundation's core guarantees hold.
#
# Every example below waits for wait_for_keyboard_nav_connected (spec/support/
# keyboard_nav_helpers.rb) before dispatching a key, and uses the raw-CDP `press`
# helper instead of Capybara's find(...).send_keys for body-level keydowns -- see
# that file's comments for why both matter on CI.
RSpec.describe "Keyboard navigation foundation", :js do
  # The expectation lives inside wait_for_keyboard_nav_connected (spec/support/
  # keyboard_nav_helpers.rb) -- RuboCop can't see through the helper call.
  it "reveals the NORMAL status line once JS has connected" do # rubocop:disable RSpec/NoExpectationExample
    visit root_path

    wait_for_keyboard_nav_connected
  end

  it "opens the guide dialog on ?" do
    visit root_path
    wait_for_keyboard_nav_connected

    press("?")

    expect(page).to have_selector("dialog#keyboard-guide-dialog[open]")
  end

  # Two expectations: the open precondition matters here (this example proves Esc
  # closes it, which requires first confirming it actually opened), so this is one
  # coherent open-then-close flow, not two unrelated assertions bolted together.
  it "closes the guide dialog on Esc" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    press("?")
    expect(page).to have_selector("dialog#keyboard-guide-dialog[open]")

    press(:escape)

    expect(page).to have_no_selector("dialog#keyboard-guide-dialog[open]")
  end

  it "never intercepts a keystroke while the existing theme <select> has focus" do
    visit root_path
    wait_for_keyboard_nav_connected

    # A real click+focus on the <select> is exactly what this example needs to
    # exercise (the isEditableTarget bail), unlike the body-wide keydowns above --
    # so this intentionally keeps Capybara's find(...).send_keys rather than the
    # raw-CDP `press` helper.
    find("#theme-picker-select").send_keys("?")

    expect(page).to have_no_selector("dialog#keyboard-guide-dialog[open]")
  end

  it "ignores modifier-chorded keys, leaving browser/OS shortcuts unconflicted" do
    visit root_path
    wait_for_keyboard_nav_connected

    press([:control, "?"])

    expect(page).to have_no_selector("dialog#keyboard-guide-dialog[open]")
  end

  # Longer than the default limit because it must exercise several real Turbo
  # navigations (each with its own connect-wait) before the single assertion that
  # matters -- splitting it up would just hide the sequence this example exists to
  # prove.
  #
  # Deliberate, bounded quarantine (#1233): this example still flakes on CI even with
  # the stale-DOM-race fix below (capture_keyboard_status_line / wait_for_keyboard_nav_
  # reconnect, added for #1236) in place -- the residual failure does NOT reproduce
  # locally and its root cause is unexplained (full writeup: #1238). `retry: 3`
  # (rspec-retry, wired up in spec/rails_helper.rb with a suite-wide
  # default_retry_count of 1 -- i.e. no retry anywhere else) is a stopgap so CI stops
  # flaking while #1238 tracks the real fix. Remove this tag once #1238 lands; do not
  # widen it to other examples.
  it "attaches exactly one document keydown listener across repeated Turbo navigations", retry: 3 do # rubocop:disable RSpec/ExampleLength
    visit root_path
    wait_for_keyboard_nav_connected

    # Terminal-identity redesign (#1226): nav text is lowercase now, and Home has no
    # separate nav item -- its data-nav-target lives on the logo link -- so "Home" hops
    # below select it via that data hook rather than visible link text.
    [
      -> { within("header") { click_link "writing" } },
      -> { within("header") { find("a[data-nav-target='home']").click } },
      -> { within("header") { click_link "projects" } },
      -> { within("header") { find("a[data-nav-target='home']").click } }
    ].each do |navigate|
      # Standard (non-permanent) Turbo visits replace <body>, disconnecting and
      # reconnecting this controller on every navigation (see the controller's own
      # Turbo lifecycle note) -- wait for the fresh instance to reconnect before the
      # next navigation/keypress, or the same connect race this file exists to guard
      # against reappears after every hop. Plain wait_for_keyboard_nav_connected isn't
      # enough here (#1233): it can match the OUTGOING page's still-live status line
      # instead of the incoming one (see that method's own comment in
      # keyboard_nav_helpers.rb), so capture the outgoing node first and route through
      # wait_for_keyboard_nav_reconnect, which proves the swap actually happened
      # before checking connect().
      outgoing_status_line = capture_keyboard_status_line
      navigate.call
      wait_for_keyboard_nav_reconnect(outgoing_status_line)
    end

    # If a prior navigation left a stale listener attached, this single "?" would
    # trigger showModal() twice in the same dispatch -- Cuprite's js_errors: true
    # (spec/support/capybara.rb) turns that double-call's thrown JS exception into a
    # Ruby error, failing this example.
    press("?")

    expect(page).to have_selector("dialog#keyboard-guide-dialog[open]")
  end

  # Increment 0's own acceptance criterion (docs/specs/1187-modal-vim-keyboard-navigation.md):
  # "Typing in the P1.1 theme <select> and any other native field on every existing route is
  # completely unaffected -- verified by an automated Capybara spec covering every route in
  # R11's list, not just manual spot-checks." Every other keyboard-nav `:js` spec in this
  # suite exercises the editable-target guard on exactly one route (root_path, or a single
  # post_path fixture) -- meaningful coverage of *that* route, but not yet this criterion's
  # literal "every route" claim. This closes that gap: the same real-browser guard check
  # (typing "?" into the native theme <select> must never open the guide dialog), repeated
  # across every route named in R11's own smoke-test list. `file_path` overrides on the
  # post/project fixtures mirror the existing convention in
  # keyboard_nav_no_js_spec.rb/keyboard_nav_hint_jump_spec.rb -- the factory defaults don't
  # point at real on-disk markdown/content, but Post#content does read a real file from disk
  # to render the show page.
  it "keeps the editable-target guard intact on every route named in R11's smoke-test list" do # rubocop:disable RSpec/ExampleLength
    post = create(:post, file_path: "2024-06-13-Hosting-Your-Personal-Site-On-AWS-S3.md")
    project = create(:project)

    [root_path, posts_path, post_path(slug: post.slug), projects_path, project_path(slug: project.slug), resume_path].each do |path|
      visit path
      wait_for_keyboard_nav_connected

      find("#theme-picker-select").send_keys("?")

      expect(page).to have_no_selector("dialog#keyboard-guide-dialog[open]")
    end
  end
end
