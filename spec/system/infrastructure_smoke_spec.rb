# frozen_string_literal: true

require "rails_helper"

# Increment 0 smoke test: proves the Capybara + Cuprite (headless Chrome)
# system-spec infrastructure is wired end-to-end -- a real browser boots,
# loads the app, and runs a JS-observable assertion. Comprehensive coverage
# of the keyboard-nav layer itself lands with each later increment (owned by
# the test agent per docs/specs/1187-modal-vim-keyboard-navigation.md).
RSpec.describe "Test infrastructure smoke test", :js do
  it "boots a real headless browser and renders the homepage" do
    visit root_path

    expect(page).to have_content("James Ebentier")
  end
end
