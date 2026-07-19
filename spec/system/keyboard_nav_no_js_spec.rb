# frozen_string_literal: true

require "rails_helper"

# Increment 6 coverage (R11 in docs/specs/1187-modal-vim-keyboard-navigation.md): "100% of
# site navigation/search/links function with the layer entirely absent." The spec's own
# Testing Strategy section notes Capybara/Cuprite (real headless Chrome, `:js` specs)
# "always runs JS ... cannot assert a JS-disabled page load," and files that check under
# "manual verification" as a result -- but Capybara's OTHER, default driver (rack_test,
# spec/support/capybara.rb: `Capybara.default_driver = :rack_test`, used for every
# `type: :system` spec that doesn't opt into `:js: true`) never executes JS at all. That
# makes a plain rack_test-driven system spec a genuine, automated equivalent of "the
# keyboard-nav layer is entirely absent" -- not a simulation of it, since no script tag on
# the page ever runs under this driver -- across every route named in R11's smoke-test
# list. This does not replace a final real-browser, JS-disabled manual spot-check before
# merge (rack_test can't prove e.g. a browser's own JS-disable setting behaves
# identically), but it is real, checked-in, CI-enforced coverage of the same claim, not a
# gap. No `press`/`wait_for_keyboard_nav_connected` calls anywhere in this file -- both
# assume a real browser executing keyboard_nav_controller.js, which is exactly what this
# file must NOT depend on.
RSpec.describe "Keyboard navigation layer absent -- progressive enhancement smoke (R11)" do
  # file_path override matches the existing convention in keyboard_nav_hint_jump_spec.rb/
  # keyboard_nav_normal_navigation_spec.rb/keyboard_nav_search_spec.rb -- the factory
  # default (spec/factories/post.rb) doesn't point at a real file under public/blog/, but
  # Post#content (app/models/post.rb) reads the actual markdown file from disk to render
  # blog/show.html.erb, so a real, on-disk fixture is required here too.
  let!(:post) { create(:post, file_path: "2024-06-13-Hosting-Your-Personal-Site-On-AWS-S3.md") }
  let!(:project) { create(:project) }

  # R11's own route list: "/", "/blog", "/blog/:slug", "/projects", "/projects/:slug",
  # "/resume".
  it "renders every existing route with a 200 and the standard header nav, with JS never executing" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    [root_path, posts_path, post_path(slug: post.slug), projects_path, project_path(slug: project.slug), resume_path]
      .each do |path|
        visit path

        expect(page).to have_selector("header a[data-nav-target='home']")
        expect(page).to have_selector("header a[data-nav-target='writing']")
        expect(page).to have_selector("header a[data-nav-target='projects']")
        expect(page).to have_selector("header a[data-nav-target='resume']")
      end
  end

  it "navigates via the real header links alone (root -> writing -> projects -> resume -> home), with no JS involved" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path

    within("header") { click_link "Blog" }
    expect(page).to have_current_path(posts_path)

    within("header") { click_link "Projects" }
    expect(page).to have_current_path(projects_path)

    within("header") { click_link "Resume" }
    expect(page).to have_current_path(resume_path)

    within("header") { click_link "Home" }
    expect(page).to have_current_path(root_path)
  end

  it "reaches a real post and a real project via their own rendered links, with no JS involved" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit posts_path
    click_link post.title
    expect(page).to have_current_path(post_path(slug: post.slug))

    # The project card's title itself isn't a link (components/_card's whole-card overlay
    # is aria-hidden/tabindex=-1, a pointer-only convenience -- see that partial's own
    # comment); "View Project" is the real, labeled, accessible link every keyboard/
    # screen-reader user reaches the same destination through, so it's the one this
    # progressive-enhancement check follows. Only one project exists in this example, so
    # there is exactly one such link -- no scoping needed to disambiguate.
    visit projects_path
    click_link "View Project"
    expect(page).to have_current_path(project_path(slug: project.slug))
  end

  it "still renders the theme <select> as a real, working native form control with JS entirely absent" do # rubocop:disable RSpec/MultipleExpectations
    visit root_path

    expect(page).to have_select("theme-picker-select", options: %w[light dark dracula nord gruvbox catppuccin])
    # A real <select>/<option> pair -- proving the control itself is a genuine native
    # form element (not something only a JS-driven widget renders), independent of
    # theme_picker_controller.js#change ever running to persist the choice.
    select "dracula", from: "theme-picker-select"
    expect(page).to have_select("theme-picker-select", selected: "dracula")
  end

  it "server-renders the keyboard-nav layer's own markup without it doing anything -- purely additive, per R11" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    visit root_path

    expect(page).to have_selector("#keyboard-status-line", visible: :all)
    expect(page).to have_selector("#keyboard-command-bar", visible: :all)
    expect(page).to have_selector("#keyboard-hint-overlay", visible: :all)
    expect(page).to have_selector("dialog#keyboard-guide-dialog", visible: :all)
    # The existing accessible link structure (this same header) is what R11 requires to
    # keep working -- already proven above; this example only adds that the keyboard-nav
    # partials' mere presence in the DOM changes nothing about that.
    expect(page).to have_selector("header a[data-nav-target='home']")
  end
end
