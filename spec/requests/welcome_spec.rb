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

  describe "GET / — hero ASCII-art terminal monogram (1181 P2 amendment)" do
    def ascii_art
      response.parsed_body.at_css("pre[aria-hidden='true']")
    end

    it "renders the monogram as a decorative element with no assistive-tech exposure" do
      get root_path

      expect(ascii_art).to be_present
    end

    it "colors the monogram solely via daisyUI design-system tokens -- no hardcoded hex, no arbitrary-value utilities" do
      get root_path

      expect(ascii_art.classes).to include("text-primary", "bg-base-200", "border-base-300")
      expect(ascii_art.classes.grep(/[\[#]/)).to be_empty
      expect(ascii_art["style"]).to be_nil
    end

    it "does not use the retired rainbow hero utilities on the monogram (1181 R10)" do
      get root_path

      expect(ascii_art.classes).not_to include(
        "text-green-500", "text-purple-500", "text-orange-500", "text-pink-500", "text-yellow-600", "text-fuchsia-500"
      )
    end

    it "hides the monogram below the md breakpoint and reveals it at md+ (1181 P2 amendment)" do
      get root_path

      expect(ascii_art.parent.classes).to include("hidden", "md:flex")
    end
  end

  describe "GET / — meta tags (1181 P2 amendment)" do
    it "renders the new software-architect page title, not the retired fractional/CTO framing" do
      get root_path

      title = response.parsed_body.at_css("title").text

      expect(title).to include("James Ebentier — Software Architect")
      expect(title).not_to include("Fractional")
      expect(title).not_to include("CTO")
    end

    it "renders the new software-architect meta description, not the retired fractional/CTO framing" do
      get root_path

      description = response.parsed_body.at_css("meta[name='description']")["content"]

      expect(description).to eq(
        "Software architect based in Berlin. I help engineering teams get their systems right — " \
          "a fraction of the time, all of the leverage."
      )
      expect(description).not_to include("Fractional")
      expect(description).not_to include("CTO")
    end
  end

  # Featured Projects / Latest Writing (1181 R2/R3/R4) -- exercises the components through the
  # real controller/view stack (see adlc/methods/code-quality/call-site-wiring-verification.md),
  # proving Project.for_home/Post.for_home are actually wired into the page and composed through
  # the real components/card + components/pill partials. Curated-first/chronological-fallback
  # ordering itself is covered at the model level (spec/models/{post,project}_spec.rb); these
  # specs only need one project/post to prove the wiring, per the pyramid-placement principle.
  describe "GET / — Featured Projects and Latest Writing" do
    def section_titled(title)
      response.parsed_body.css("section").find { |section| section.at_css("h2.text-2xl")&.text == title }
    end

    context "when there is a featured project and a published post" do
      let!(:project) do
        create(:project, slug: "featured-project", title: "Featured Project", status: "Live", featured: true)
      end
      let!(:post) { create(:post, slug: "featured-post", title: "Featured Post") }

      it "wraps the project in a card whose stretched-link overlay points at the project's own page (R3)" do
        get root_path

        featured_section = section_titled("Featured Projects")

        expect(URI.parse(featured_section.at_css("a.absolute")["href"]).path).to eq(project_path(slug: project.slug))
      end

      it "renders the project's status pill inside the Featured Projects card (R3)" do
        get root_path

        featured_section = section_titled("Featured Projects")

        expect(featured_section.at_css(".badge").classes).to include("badge-success")
      end

      it "wraps the post in a card whose stretched-link overlay points at the post's own page (R4)" do
        get root_path

        writing_section = section_titled("Latest Writing")

        expect(URI.parse(writing_section.at_css("a.absolute")["href"]).path).to eq(post_path(slug: post.slug))
      end

      it "does not render a status pill inside the Latest Writing card -- pill is project-only (R4)" do
        get root_path

        writing_section = section_titled("Latest Writing")

        expect(writing_section.css(".badge")).to be_empty
      end

      it "uses the responsive one-column-to-three-column grid for Featured Projects (R6)" do
        get root_path

        grid = section_titled("Featured Projects").at_css("div.grid")

        expect(grid.classes).to include("grid-cols-1", "md:grid-cols-3")
      end

      it "uses the responsive one-column-to-three-column grid for Latest Writing (R6)" do
        get root_path

        grid = section_titled("Latest Writing").at_css("div.grid")

        expect(grid.classes).to include("grid-cols-1", "md:grid-cols-3")
      end
    end

    context "when there are no projects" do
      before { create(:post) }

      it "omits the Featured Projects section entirely (R2/R3)" do
        get root_path

        expect(section_titled("Featured Projects")).to be_nil
      end

      it "still renders the Latest Writing section" do
        get root_path

        expect(section_titled("Latest Writing")).to be_present
      end
    end

    context "when there are no posts" do
      before { create(:project) }

      it "omits the Latest Writing section entirely (R2/R4)" do
        get root_path

        expect(section_titled("Latest Writing")).to be_nil
      end

      it "still renders the Featured Projects section" do
        get root_path

        expect(section_titled("Featured Projects")).to be_present
      end
    end
  end

  describe "GET / — Work with me CTA (1181 R5)" do
    it "links the CTA to a real mailto: address sourced from resume.yml, not a hardcoded literal" do
      get root_path

      expected_email = YAML.safe_load_file(Rails.root.join("resume/resume.yml"), symbolize_names: true).dig(:basics, :email)
      cta = response.parsed_body.css(".btn-primary").find { |link| link.text == "Work with me" }

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
end
