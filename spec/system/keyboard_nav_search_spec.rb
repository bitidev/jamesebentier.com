# frozen_string_literal: true

require "rails_helper"

# Increment 4 coverage (R7/R9 in docs/specs/1187-modal-vim-keyboard-navigation.md): SEARCH
# mode -- `/` entry (reusing the shared terminal-style bar COMMAND mode stood up), the
# lazily-fetched/tab-session-cached content index, live-filtering, n/N result-stepping
# (SEARCH-mode-scoped, not a global repeat-search), Enter's real-link activation, and the
# not-found/focus-restore semantics. Deliberately not exhaustive -- comprehensive
# per-route coverage is owned by the test agent in a later phase; these specs prove
# Increment 4's acceptance criteria hold against a real browser. rankSearchResults' own
# ranking/empty-query behavior is unit-tested in
# app/javascript/keyboard_nav/search_index.test.js, not re-proven here; the
# GET /search-index.json item shape (including the excerpt fallback) is request-spec-
# tested in spec/requests/search_index_spec.rb, not re-proven here either.
#
# Every example below calls wait_for_keyboard_nav_connected (spec/support/
# keyboard_nav_helpers.rb) right after `visit`, before any key dispatch, and uses the
# raw-CDP `press` helper (also from that shared file) for the very first, body-level `/`
# keydown -- see that file's comments for the CI-only connect race and the body-click
# side effect both guard against. Once focus has moved into the search input itself,
# typing/n/N/Enter use ordinary Capybara `fill_in`/`send_keys` -- there is no ambiguous
# full-height-body-click concern for a small, on-screen, already-focused <input>.
RSpec.describe "Keyboard navigation -- SEARCH mode (/)", :js do
  # Long markdown fixture for search-index coverage (distinct from the factory default).
  # The Enter-navigates test below visits this post's show page, which reads the file from disk.
  let!(:aws_post) do
    create(
      :post,
      slug: "hosting-on-aws",
      title: "Hosting on AWS",
      description: "A guide to static hosting",
      tags: %w[aws cloud],
      file_path: "2024-06-13-Hosting-Your-Personal-Site-On-AWS-S3.md"
    )
  end

  # Only referenced by their rendered title text below, never by variable name -- plain
  # `before`-block creates (not `let!`) so RSpec/LetSetup doesn't flag them.
  before do
    create(:post, slug: "learning-vim-motions", title: "Learning Vim Motions", description: "hjkl and beyond", tags: %w[vim keyboard])
    create(:project, slug: "vimium-clone", title: "Vimium Clone", status: "Live")
  end

  it "opens the bar, moves focus into it, and switches the status line to SEARCH" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    expect(page).to have_no_selector("#keyboard-command-bar")

    press("/")

    expect(page).to have_selector("#keyboard-status-line", text: "-- SEARCH --")
    expect(page).to have_selector("#keyboard-command-bar")
    expect(page).to have_selector("#keyboard-command-input:focus")
  end

  it "fetches the index lazily on first open and renders the full result set once loaded" do # rubocop:disable RSpec/NoExpectationExample -- assertion lives in wait_for_search_results
    visit root_path
    wait_for_keyboard_nav_connected
    press("/")

    wait_for_search_results(3)
  end

  it "live-filters results as the visitor types, ranking a title match in (and excluding non-matches)" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    press("/")
    wait_for_search_results(3)

    fill_in "Search", with: "vim"
    wait_for_search_results(2)

    # Terminal-identity redesign (#1226): Home's own Latest Writing block now renders
    # each recent post as a real row link with the post's title as its visible/accessible
    # text (app/views/welcome/index.html.erb) -- so with only two posts in the fixture set,
    # the underlying Home page (still in the DOM behind the SEARCH overlay) legitimately
    # contains a real "Hosting on AWS" link of its own. Scoping to #keyboard-search-results
    # (the overlay's own result list, app/views/layouts/components/_keyboard_command_bar.
    # html.erb) is what actually proves the *filtering*, independent of whatever the host
    # page underneath happens to render.
    within("#keyboard-search-results") do
      expect(page).to have_link("Learning Vim Motions")
      expect(page).to have_link("Vimium Clone")
      expect(page).to have_no_link("Hosting on AWS")
    end
  end

  it "highlights the first result by default and steps the highlight with n/N, scoped to the open list" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    press("/")
    fill_in "Search", with: "vim"
    wait_for_search_results(2)

    expect(find("[data-search-highlighted='true']")).to have_text("Learning Vim Motions")

    find("#keyboard-command-input").send_keys("n")
    expect(find("[data-search-highlighted='true']")).to have_text("Vimium Clone")

    find("#keyboard-command-input").send_keys("N")
    expect(find("[data-search-highlighted='true']")).to have_text("Learning Vim Motions")
  end

  it "wraps n past the last result back to the first" do # rubocop:disable RSpec/ExampleLength
    visit root_path
    wait_for_keyboard_nav_connected
    press("/")
    fill_in "Search", with: "vim"
    wait_for_search_results(2)

    find("#keyboard-command-input").send_keys("n")
    find("#keyboard-command-input").send_keys("n")

    expect(find("[data-search-highlighted='true']")).to have_text("Learning Vim Motions")
  end

  it "reserves n/N as result-stepping keys, so they are never inserted into the query text (a named trade-off, R7)" do # rubocop:disable RSpec/ExampleLength
    visit root_path
    wait_for_keyboard_nav_connected
    press("/")
    fill_in "Search", with: "vi"
    wait_for_search_results(2)

    find("#keyboard-command-input").send_keys("n")

    expect(page).to have_field("Search", with: "vi")
  end

  it "Enter activates the highlighted result via a real navigation to its actual URL" do # rubocop:disable RSpec/ExampleLength
    visit root_path
    wait_for_keyboard_nav_connected
    press("/")
    fill_in "Search", with: "aws"
    wait_for_search_results(1)

    find("#keyboard-command-input").send_keys(:enter)

    expect(page).to have_current_path(post_path(slug: aws_post.slug))
  end

  it "shows a no-match state and leaves Enter a no-op (no navigation) when nothing matches" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    press("/")
    wait_for_search_results(3)

    fill_in "Search", with: "zzz-no-such-content-zzz"

    expect(page).to have_no_selector("#keyboard-search-results li")
    expect(page).to have_selector("[data-keyboard-nav-target='commandFeedback']", text: "no matching")

    find("#keyboard-command-input").send_keys(:enter)

    expect(page).to have_current_path(root_path)
    expect(page).to have_selector("#keyboard-status-line", text: "-- SEARCH --")
  end

  it "restores focus, on Esc, to whatever had it before entry -- not assumed to be document.body" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    page.evaluate_script('document.querySelector("[data-nav-target=\"projects\"]").focus()')

    press("/")
    expect(page).to have_selector("#keyboard-command-bar")

    press(:escape)

    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")
    expect(page).to have_selector("[data-nav-target='projects']:focus")
    expect(page).to have_no_selector("#keyboard-search-results li")
  end

  it "keeps / inert while the existing theme <select> has focus (no bar, no mode change)" do # rubocop:disable RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected

    find("#theme-picker-select").send_keys("/")

    expect(page).to have_no_selector("#keyboard-command-bar")
    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")
  end

  it "does not re-fetch the index on a second `/` open in the same tab session" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    clear_network_traffic!

    press("/")
    wait_for_search_results(3)
    press(:escape)
    # Synchronize on Escape's mode transition (status line back to NORMAL) before
    # sending the next raw keydown -- `press` has no built-in wait, so without this
    # the very next "/" can race ahead of Escape's own async settling and land while
    # SEARCH's <input> still has focus, making it a no-op typed character instead of
    # a fresh NORMAL-mode `/` (a real, reproduced flake, not a hypothetical one).
    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")

    press("/")
    wait_for_search_results(3)

    expect(search_index_request_count).to eq(1)
  end

  it "keeps the cached index across a Turbo-driven navigation (module-level cache, not per-controller-instance)" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path
    wait_for_keyboard_nav_connected
    clear_network_traffic!

    press("/")
    wait_for_search_results(3)
    press(:escape)
    # See the comment in the example above: synchronize on Escape's mode transition
    # before the next raw keydown (here, the g-prefix page jump) so it can't race
    # ahead and land while SEARCH's <input> still has focus.
    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")

    # Same stale-DOM race wait_for_keyboard_nav_connected's own comment documents
    # (#1233): g p navigates via a real .click() on the projects header link
    # (navigateTo, keyboard_nav_controller.js), the exact same Turbo body-swap this
    # example was already in NORMAL mode for (see the "-- NORMAL --" check just
    # above) -- so a plain wait_for_keyboard_nav_connected here could match the
    # OUTGOING page's still-live status line before the incoming page's connect()
    # has attached its listener, silently swallowing the press("/") below. Capture
    # the outgoing node first and route through wait_for_keyboard_nav_reconnect,
    # exactly like keyboard_nav_spec.rb's repeated-navigation example does.
    outgoing_status_line = capture_keyboard_status_line
    press("g", "p")
    expect(page).to have_current_path(projects_path)
    wait_for_keyboard_nav_reconnect(outgoing_status_line)

    press("/")
    wait_for_search_results(3)

    expect(search_index_request_count).to eq(1)
  end
end
