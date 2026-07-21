# frozen_string_literal: true

require "rails_helper"

RSpec.describe "About page (1184)" do
  let(:expected_email) do
    YAML.safe_load_file(Rails.root.join("resume/resume.yml"), symbolize_names: true).dig(:basics, :email)
  end

  describe "GET /about" do
    it "returns a successful response" do
      get about_path

      expect(response).to have_http_status(:ok)
    end

    it "sets the about page title meta tag" do
      get about_path

      expect(response.body).to include("About — James Ebentier")
    end

    # Terminal-identity redesign (#1226), operator decision #1: drop "fractional"/"CTO"
    # everywhere, including the About meta description (docs/design/2026-07-21-terminal-
    # redesign-design.md's "Decisions" + About section).
    it "sets the de-fractionalized about page description meta tag" do
      get about_path

      expect(response.body).to include(
        "Software architect based in Berlin. I help engineering teams get their systems right"
      )
    end

    it "does not render the retired 'Fractional' framing in the about page description" do
      get about_path

      description = response.parsed_body.at_css("meta[name='description']")["content"]

      expect(description).not_to include("Fractional")
    end

    it "carries the positioning line as the page <h1>" do
      get about_path

      expect(response.parsed_body.at_css("h1").text).to include(
        "I help engineers get their systems right — a fraction of the time, all of the leverage."
      )
    end

    it "renders at least one Work with me CTA on about" do
      get about_path

      # Terminal-identity redesign (#1226): the visible CTA label is now "[ work with me ]"
      # -- the accessible name "Work with me" lives on aria-label instead (see welcome_spec).
      ctas = response.parsed_body.css("a.btn-primary[aria-label='Work with me']")

      expect(ctas).not_to be_empty
    end

    it "links each about-page Work with me CTA to resume.yml mailto" do
      get about_path

      ctas = response.parsed_body.css("a.btn-primary[aria-label='Work with me']")

      expect(ctas.pluck("href")).to all(eq("mailto:#{expected_email}"))
    end

    it "includes the 'what I do' and 'how I work' section headings" do
      get about_path

      # Terminal-identity redesign (#1226): section headers are now lowercase markdown-
      # style ("## what I do" / "## how I work"), not the old title-case "What I do"/
      # "How I work" prose headings.
      body = response.parsed_body
      expect(body.text).to include("## what I do", "## how I work")
    end

    it "includes a proof link to projects" do
      get about_path

      project_link_texts = response.parsed_body.css("a[href*='projects']").map(&:text)
      expect(project_link_texts).to include("what I've shipped")
    end

    it "includes a proof link to writing" do
      get about_path

      writing_link_texts = response.parsed_body.css("a[href*='writing']").map(&:text)
      expect(writing_link_texts).to include("what I've written")
    end
  end

  # Terminal-identity redesign (#1226): the shared footer (identity/sitemap/newsletter) now
  # renders Home-only (ApplicationHelper#show_full_footer?, app/views/layouts/application.
  # html.erb) -- interior pages, including About, end at the statusline with no <footer> at
  # all. The old "shared CTA/About link in the footer" assertions only make sense on Home
  # now; the About-side CTA is covered above ("renders at least one Work with me CTA on
  # about"), and Home's own CTA/footer wiring is covered in welcome_spec.
  describe "footer" do
    it "renders no footer on the about page" do
      get about_path

      expect(response.parsed_body.at_css("footer")).to be_nil
    end
  end

  describe "navigation" do
    it "includes an About link in the header for future keyboard nav wiring" do
      get about_path

      # Terminal-identity redesign (#1226): header nav link text is now lowercase.
      about_link = response.parsed_body.at_css("header a[data-nav-target='about']")
      expect(about_link.text).to eq("about")
    end

    it "links the header About nav item to /about" do
      get about_path

      about_link = response.parsed_body.at_css("header a[data-nav-target='about']")
      expect(about_link["href"]).to eq(about_path)
    end
  end
end
