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

    it "sets the about page description meta tag" do
      get about_path

      expect(response.body).to include("Fractional software architect based in Berlin")
    end

    it "carries the positioning line as the page <h1>" do
      get about_path

      expect(response.parsed_body.at_css("h1").text).to include(
        "I help engineers get their systems right — a fraction of the time, all of the leverage."
      )
    end

    it "renders at least one Work with me CTA on about" do
      get about_path

      ctas = response.parsed_body.css("a.btn-primary").select { |link| link.text == "Work with me" }

      expect(ctas).not_to be_empty
    end

    it "links each about-page Work with me CTA to resume.yml mailto" do
      get about_path

      ctas = response.parsed_body.css("a.btn-primary").select { |link| link.text == "Work with me" }

      expect(ctas.pluck("href")).to all(eq("mailto:#{expected_email}"))
    end

    it "includes the What I do and How I work section headings" do
      get about_path

      body = response.parsed_body
      expect(body.text).to include("What I do", "How I work")
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

  describe "shared Work with me CTA placement" do
    it "renders the CTA on the home page" do
      get root_path

      cta = response.parsed_body.css("a.btn-primary").find { |link| link.text == "Work with me" }
      expect(cta["href"]).to eq("mailto:#{expected_email}")
    end

    it "renders the CTA in the site footer" do
      get root_path

      footer = response.parsed_body.at_css("footer")
      footer_cta = footer.css("a.btn-primary").find { |link| link.text == "Work with me" }

      expect(footer_cta["href"]).to eq("mailto:#{expected_email}")
    end
  end

  describe "navigation" do
    it "includes an About link in the header for future keyboard nav wiring" do
      get about_path

      about_link = response.parsed_body.at_css("header a[data-nav-target='about']")
      expect(about_link.text).to eq("About")
    end

    it "links the header About nav item to /about" do
      get about_path

      about_link = response.parsed_body.at_css("header a[data-nav-target='about']")
      expect(about_link["href"]).to eq(about_path)
    end

    it "includes an About link in the footer Links column" do
      get about_path

      footer_links = response.parsed_body.at_css("footer").css("a").map(&:text)
      expect(footer_links).to include("About")
    end
  end
end
