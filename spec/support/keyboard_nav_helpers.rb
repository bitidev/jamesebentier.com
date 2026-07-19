# frozen_string_literal: true

# Shared helpers for the keyboard-nav system specs (spec/system/keyboard_nav_spec.rb,
# spec/system/keyboard_nav_normal_navigation_spec.rb). See
# docs/specs/1187-modal-vim-keyboard-navigation.md.
#
# Both helpers exist to harden these specs against a real CI-only race: on a
# loaded/cold GitHub Actions runner, keyboard_nav_controller#connect() (see
# app/javascript/controllers/keyboard_nav_controller.js) can take measurably longer
# to run than it does locally (warm asset cache, idle machine). A key dispatched
# immediately after `visit`/a Turbo navigation can therefore be sent before the
# document-level keydown listener exists to receive it -- silently swallowed, no
# error, just no effect. This reproduced 8/8 of the CI-only failures on run
# 29686067631 (dialog never opens, scroll/nav keys have zero effect) while every
# spec passed 100% locally, including under 100x CDP CPU throttling -- consistent
# with CI-only asset-serving/compile latency delaying connect(), not a genuine
# headless-Chrome product bug.
module KeyboardNavHelpers
  # Ceiling for the Stimulus-connect wait below -- a small margin over Capybara's
  # 5s default_max_wait_time (spec/support/capybara.rb), just to absorb a slow first
  # JS parse/execute on a loaded CI runner. It is NOT the mechanism that made these
  # specs pass on CI: connect() failing to run on headless was NOT a boot-timing race
  # (an earlier 30s widening still failed at 30s) but the R12 hover/fine-pointer gate
  # bailing under Linux headless -- fixed at the driver level by forcing hover/fine
  # via --blink-settings (see CUPRITE_DRIVER_OPTIONS in spec/support/capybara.rb).
  # With that in place connect() runs on page load like it does locally, so this wait
  # is back to ordinary "wait for JS to have run" territory; the modest ceiling is
  # just insurance, and have_selector returns the instant the text appears.
  KEYBOARD_NAV_CONNECT_TIMEOUT = 10

  # Ceiling for waiting on SEARCH's results list to render (spec/system/
  # keyboard_nav_search_spec.rb) -- a small margin over Capybara's 5s
  # default_max_wait_time, mirroring KEYBOARD_NAV_CONNECT_TIMEOUT's own rationale.
  # Populating #keyboard-search-results involves a genuine extra round trip beyond
  # ordinary JS execution (fetchSearchIndex's GET /search-index.json plus its own
  # response.json() parse, spec R7/R9), so it can occasionally take a beat longer
  # than the default wait under a loaded test-runner, independent of any product bug.
  SEARCH_RESULTS_TIMEOUT = 10

  # Blocks until keyboard_nav_controller#connect() has run. connect() un-hides
  # #keyboard-status-line (removes the "hidden" class) and modeValueChanged()
  # writes its "-- NORMAL --" text -- both happen synchronously with attaching the
  # document keydown listener, so the visible, populated status line is a true
  # proxy for "the listener now exists to receive keys."
  #
  # Two-stage on purpose (belt-and-suspenders diagnostic): first confirm the
  # element is in the DOM at all (fast -- it's server-rendered, so a failure here
  # means the markup/layout changed, not a JS problem), THEN wait up to
  # KEYBOARD_NAV_CONNECT_TIMEOUT for the text to be populated by JS. If CI ever
  # fails the SECOND wait, the element is present but connect() never ran -- a
  # genuine "JS isn't executing" problem (bundle not loaded / controller not
  # registered), not the timing issue this widened wait addresses. Deliberately
  # NOT `visible: :all` -- the text is in the server-rendered markup regardless of
  # JS, so only the default visibility filter (which respects the "hidden" class)
  # actually proves connect() ran. Call after every visit/navigation, before any
  # key.
  def wait_for_keyboard_nav_connected
    expect(page).to have_selector("#keyboard-status-line", visible: :all)
    expect(page).to have_selector(
      "#keyboard-status-line", text: "-- NORMAL --", wait: KEYBOARD_NAV_CONNECT_TIMEOUT
    )
  end

  # Dispatches real keydown/keyup CDP events directly (Ferrum's
  # Input.dispatchKeyEvent), bypassing Capybara's find(...).send_keys. Cuprite's
  # Page#send_keys (capybara-cuprite's page.rb) performs a REAL CLICK on the
  # target node first (before_click's scrollIntoViewport + mouseEventTest) -- for
  # a full-height <body>, that click lands wherever the body's bounding-rect
  # center happens to fall (an <img>, a link, arbitrary content), which both
  # scrolls the page as a side effect (corrupting scroll-position assertions) and,
  # on any layout difference between environments (e.g. image load timing), can
  # land on a real link and navigate away before the key is ever dispatched -- a
  # false pass/fail unrelated to the keyboard-nav feature under test. A bare
  # keydown with no explicit focus target lands on document.activeElement
  # (document.body by default on a fresh page load / after a Turbo visit), exactly
  # what the feature's document-level listener expects.
  def press(*keys)
    page.driver.browser.page.keyboard.type(*keys)
  end

  # Waits (up to SEARCH_RESULTS_TIMEOUT) for #keyboard-search-results to contain
  # exactly `count` <li> items -- see that constant's comment for why this needs a
  # wider margin than the default 5s wait.
  def wait_for_search_results(count)
    expect(page).to have_selector("#keyboard-search-results li", count: count, wait: SEARCH_RESULTS_TIMEOUT)
  end

  # Counts real network requests to `path_fragment` made so far (Ferrum's own
  # Network domain traffic log, spec/system/keyboard_nav_search_spec.rb) -- used to
  # prove SEARCH mode's "never re-fetch the content index in the same tab session"
  # claim (spec R7) without monkey-patching `window.fetch` in the page itself. An
  # earlier version of these specs overrode `window.fetch` via `execute_script` to
  # count calls; that destabilized Turbo's own fetch-based navigation intermittently
  # (a real, reproduced flake, not a one-off) -- Ferrum's network traffic log is a
  # passive observer with no such risk.
  def search_index_request_count
    page.driver.browser.page.network.traffic.count { |exchange| exchange.url.to_s.include?("search-index.json") }
  end

  # Ferrum's traffic log accumulates for the lifetime of the underlying page/tab, which
  # Capybara/Cuprite can reuse across multiple `visit` calls (and possibly examples) --
  # call this right after `visit`/`wait_for_keyboard_nav_connected` so
  # search_index_request_count's baseline is this example's own requests only, not
  # anything a prior visit already made.
  def clear_network_traffic!
    page.driver.browser.page.network.clear(:traffic)
  end
end

RSpec.configure do |config|
  config.include KeyboardNavHelpers, type: :system
end
