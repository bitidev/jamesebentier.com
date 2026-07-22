# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Welcomes" do
  describe "GET /" do
    let(:expected_subhead) do
      "James Ebentier — software architect based in Berlin. I embed with engineering teams " \
        "to unblock hard technical decisions and mentor the people who'll own the system long " \
        "after I'm gone."
    end

    it "returns a successful response" do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    it "does not reintroduce the retired rainbow hero utilities in the redesigned hero (1181 R10)" do
      get root_path

      expect(response.body).not_to match(/text-(green-500|purple-500|orange-500|pink-500|yellow-600|fuchsia-500)/)
    end

    it "carries the final positioning line as the hero's <h1> (1181 R1/R10)" do
      get root_path

      expect(response.parsed_body.at_css("h1").text).to include(
        "I help engineers get their systems right — a fraction of the time, all of the leverage."
      )
    end

    it "renders the terminal-flavored '$ whoami' eyebrow above the hero (1181 R1)" do
      get root_path

      expect(response.body).to include("$ whoami")
    end

    it "renders the supporting subhead beneath the positioning h1 (1181 R1)" do
      get root_path

      expect(response.parsed_body.at_css("h1").next_element.text).to eq(expected_subhead)
    end

    it "removes the old 'Software Architect for Invoca Inc.' employer claim from the hero (1181 R1)" do
      get root_path

      expect(response.body).not_to include("Invoca")
    end

    it "does not reintroduce the retired 'fractional architect & CTO' / Germany framing in the hero subhead (1181 P2 amendment)" do
      get root_path

      hero_copy = response.parsed_body.at_css("h1").parent.text

      expect(hero_copy).not_to match(/fractional|CTO|Germany/i)
    end
  end

  describe "GET / — meta tags (1181 P2 amendment)" do
    it "renders the new software-architect page title" do
      get root_path

      title = response.parsed_body.at_css("title").text

      expect(title).to include("James Ebentier — Software Architect")
    end

    it "does not render the retired 'Fractional' framing in the page title" do
      get root_path

      title = response.parsed_body.at_css("title").text

      expect(title).not_to include("Fractional")
    end

    it "does not render the retired 'CTO' framing in the page title" do
      get root_path

      title = response.parsed_body.at_css("title").text

      expect(title).not_to include("CTO")
    end

    it "renders the new software-architect meta description" do
      get root_path
      description = response.parsed_body.at_css("meta[name='description']")["content"]
      expected_description = "Software architect based in Berlin. I help engineering teams get their " \
                             "systems right — a fraction of the time, all of the leverage."

      expect(description).to eq(expected_description)
    end

    it "does not render the retired 'Fractional' framing in the meta description" do
      get root_path

      description = response.parsed_body.at_css("meta[name='description']")["content"]

      expect(description).not_to include("Fractional")
    end

    it "does not render the retired 'CTO' framing in the meta description" do
      get root_path

      description = response.parsed_body.at_css("meta[name='description']")["content"]

      expect(description).not_to include("CTO")
    end
  end

  # Featured Projects / Latest Writing (1181 R2/R3/R4) -- exercises the components through the
  # real controller/view stack (see adlc/methods/code-quality/call-site-wiring-verification.md),
  # proving Project.for_home/Post.for_home are actually wired into the page. Terminal-identity
  # redesign (#1226) replaced the old card-grid sections with terminal "session log" rows
  # (app/views/welcome/index.html.erb) -- each block is now introduced by its own shell-prompt
  # <p> ("$ ls ~/projects --featured" / "$ tail -n 3 ~/writing") followed by a flex-col list of
  # real row links, not a <section>/h2-titled card grid. `projects_block`/`writing_block` locate
  # that row list by its preceding prompt text (the one stable anchor the redesign kept), rather
  # than the retired section/h2 lookup.
  describe "GET / — Featured Projects and Latest Writing" do
    def projects_block
      prompt = response.parsed_body.css("p").find { |p| p.text.include?("ls ~/projects --featured") }
      prompt&.next_element
    end

    def writing_block
      prompt = response.parsed_body.css("p").find { |p| p.text.include?("tail -n 3 ~/writing") }
      prompt&.next_element
    end

    context "when there is a featured project and a published post" do
      let!(:project) do
        create(:project, slug: "featured-project", title: "Featured Project", status: "Live", featured: true)
      end
      let!(:post) do
        create(
          :post,
          slug: "featured-post",
          title: "Featured Post",
          description: "The SEO meta-tag description, never shown in the row body (R7)",
          excerpt: "The real excerpt -- Home rows show title/date/min only, not the excerpt (R7)"
        )
      end

      it "links the featured-project row to the project's own page (R3)" do
        get root_path

        row_link = projects_block.at_css("a")

        expect(row_link["href"]).to eq(project_url(slug: project.slug))
      end

      it "shows the project's status via its colored status dot in the row (R3)" do # rubocop:disable RSpec/MultipleExpectations
        get root_path

        status_span = projects_block.at_css("a").css("span").find { |span| span.text.strip.start_with?("●") }

        expect(status_span.classes).to include(project.status_color_class)
        expect(status_span.text).to include(project.status.downcase)
      end

      it "links the latest-writing row to the post's own page (R4)" do
        get root_path

        row_link = writing_block.at_css("a")

        expect(row_link["href"]).to eq(post_url(slug: post.slug))
      end

      it "does not render a project-style status dot inside Latest Writing rows -- that's project-only (R4)" do
        get root_path

        expect(writing_block.text).not_to include("●")
      end

      it "shows the post's title and reading time in the row, not its excerpt or description (P1.4/#1183 R7 amendment)" do # rubocop:disable RSpec/MultipleExpectations
        get root_path

        expect(writing_block.text).to include(post.title, "#{post.reading_time} min")
        expect(writing_block.text).not_to include(post.description)
      end
    end

    context "when there are no projects" do
      before { create(:post) }

      it "omits the featured-projects block entirely (R2/R3)" do
        get root_path

        expect(projects_block).to be_nil
      end

      it "still renders the latest-writing block" do
        get root_path

        expect(writing_block).to be_present
      end
    end

    context "when there are no posts" do
      before { create(:project) }

      it "omits the latest-writing block entirely (R2/R4)" do
        get root_path

        expect(writing_block).to be_nil
      end

      it "still renders the featured-projects block" do
        get root_path

        expect(projects_block).to be_present
      end
    end
  end

  # Terminal-identity redesign (#1226) PR review fix: the Home "stats" block used to render
  # a hardcoded "1,284" literal and a static sparkline. WelcomeController#index now assigns
  # @views_stats/@daily_view_counts from Analytics::StatsQuery (the same real PageView data
  # `:stats views --last 7d` queries live) -- these specs prove the figure is genuinely
  # data-driven, not a literal, in both directions (real count present, old literal gone).
  describe "GET / — real first-party stats (#1226 PR review fix)" do
    include ActionView::Helpers::NumberHelper

    def stats_block
      prompt = response.parsed_body.css("p").find { |p| p.text.include?("stats views --last 7d") }
      prompt&.next_element
    end

    it "never renders the retired hardcoded '1,284' stats literal" do
      get root_path

      expect(response.body).not_to include("1,284")
    end

    context "when page views exist in the last 7 days" do
      it "shows the real total (human + bot), via number_with_delimiter, not a hardcoded figure" do
        create_list(:page_view, 4, recorded_at: 1.day.ago, visitor_type: "human")
        create(:page_view, :bot, recorded_at: 2.days.ago)

        get root_path

        figure = stats_block.at_css("span.font-bold")

        expect(figure.text).to eq(number_with_delimiter(5))
      end

      it "reflects the real total in the sr-only label" do
        create_list(:page_view, 4, recorded_at: 1.day.ago, visitor_type: "human")
        create(:page_view, :bot, recorded_at: 2.days.ago)

        get root_path

        expect(stats_block.at_css("span.sr-only").text).to eq("5 views over the last 7 days")
      end

      it "excludes page views recorded outside the 7-day window from the total" do
        create(:page_view, recorded_at: 1.day.ago)
        create(:page_view, recorded_at: 8.days.ago)

        get root_path

        figure = stats_block.at_css("span.font-bold")

        expect(figure.text).to eq(number_with_delimiter(1))
      end
    end

    context "when there are no page views at all (brand-new DB)" do
      it "renders '0 views' honestly rather than hiding the stats block" do # rubocop:disable RSpec/MultipleExpectations
        get root_path

        expect(stats_block).to be_present
        expect(stats_block.at_css("span.font-bold").text).to eq("0")
        expect(stats_block.at_css("span.sr-only").text).to eq("0 views over the last 7 days")
      end
    end
  end

  describe "GET / — Work with me CTA (1181 R5)" do
    it "links the CTA to a real mailto: address sourced from resume.yml, not a hardcoded literal" do
      get root_path

      expected_email = YAML.safe_load_file(Rails.root.join("resume/resume.yml"), symbolize_names: true).dig(:basics, :email)
      # Terminal-identity redesign (#1226): the visible label is now the stylized
      # "[ work with me ]" (brackets, lowercase) -- the accessible name "Work with me" lives
      # on aria-label instead (components/_cta_button.html.erb's aria_label local), so the
      # CTA is located by that real accessible-name selector rather than by link text.
      cta = response.parsed_body.at_css("a.btn-primary[aria-label='Work with me']")

      expect(cta["href"]).to eq("mailto:#{expected_email}")
    end
  end

  describe "the theme picker (R4/R6)" do
    it "lists exactly the six approved themes, in R4's documented order" do
      get root_path
      option_values = response.parsed_body.css("#theme-picker-select option").pluck("value")

      expect(option_values).to eq(%w[light dark dracula nord gruvbox catppuccin])
    end
  end

  describe "GET / — newsletter signup form (#1186)" do
    it "renders an email input on the home page" do
      get root_path

      expect(response.parsed_body.at_css("input[type='email'][name='subscriber[email]']")).to be_present
    end

    it "renders the newsletter form pointing at /newsletter" do
      get root_path

      forms = response.parsed_body.css("form[action='/newsletter']")

      expect(forms).not_to be_empty
    end

    it "renders the consent checkbox on the home page" do
      get root_path

      expect(response.parsed_body.at_css("input[type='checkbox'][name='subscriber[consent]']")).to be_present
    end

    it "links the consent label to the privacy policy page" do
      get root_path

      expect(response.parsed_body.at_css("a[href='#{privacy_path}']")).to be_present
    end
  end

  describe "GET / — footer newsletter signup form (#1186)" do
    it "renders at least two newsletter forms (one in body, one in footer)" do
      get root_path

      forms = response.parsed_body.css("form[action='/newsletter']")

      expect(forms.size).to be >= 2
    end

    it "renders the footer newsletter form inside the footer element" do
      get root_path

      footer_forms = response.parsed_body.at_css("footer").css("form[action='/newsletter']")

      expect(footer_forms).not_to be_empty
    end
  end

  # Legal pages (#1190): the shared footer only renders on Home (ApplicationHelper#
  # show_full_footer?, see about_spec's "footer" block), so this is the one place the
  # Impressum/Privacy links can be exercised through the real controller/view stack.
  describe "GET / — footer legal links (#1190)" do
    it "links to the Impressum page from the footer" do
      get root_path

      footer_link = response.parsed_body.at_css("footer a[href='#{impressum_path}']")

      expect(footer_link.text).to eq("Impressum")
    end

    it "links to the Privacy Policy page from the footer" do
      get root_path

      footer_link = response.parsed_body.at_css("footer a[href='#{privacy_path}']")

      expect(footer_link.text).to eq("Privacy")
    end
  end

  # Build-in-public site version (#1191): the footer's "james@ebentier" prompt line links a
  # "v<version>" tag to /changelog, sourced from Changelog.current_version -- the very same
  # object the /changelog page itself renders (see spec/models/changelog_spec.rb and
  # spec/requests/changelog_spec.rb). Deriving the expected text from Changelog.current_version
  # here, rather than hardcoding "v1.3.0", is the point: it proves the footer and the model
  # can't drift apart, not just that today's fixture happens to match.
  describe "GET / — footer site version (#1191)" do
    it "shows the current site version, linked to /changelog, on the james@ebentier prompt line" do # rubocop:disable RSpec/MultipleExpectations
      get root_path

      version_link = response.parsed_body.css("footer a[href='#{changelog_path}']").find { |a| a.text.start_with?("v") }

      expect(version_link).to be_present
      expect(version_link.text).to eq("v#{Changelog.current_version}")
    end

    it "links the footer sitemap's /changelog entry to the changelog page" do
      get root_path

      sitemap_link = response.parsed_body.css("footer a[href='#{changelog_path}']").find { |a| a.text == "/changelog" }

      expect(sitemap_link).to be_present
    end
  end
end
