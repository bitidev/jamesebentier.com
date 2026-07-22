# frozen_string_literal: true

require "rails_helper"

# SEO / meta / structured-data polish (#1189 design doc). Covers the site-wide contract
# (Person + WebSite JSON-LD, a canonical, on every page), the filtered-index canonical
# query-strip, and the post-page-specific contract (BlogPosting JSON-LD, og:type=article,
# article:* meta, and the resolved_og_image fallback/no-doubling behavior) end to end
# through the real controller/view stack -- not just the helper unit specs.
RSpec.describe "SEO structured data and meta (#1189)" do
  def json_ld_blocks
    response.parsed_body.css('script[type="application/ld+json"]').map { |node| JSON.parse(node.text) }
  end

  def canonical_href
    response.parsed_body.at_css("link[rel='canonical']")&.[]("href")
  end

  def meta_content(selector)
    response.parsed_body.at_css(selector)&.[]("content")
  end

  describe "site-wide Person + WebSite JSON-LD and canonical" do
    it "renders a Person and a WebSite JSON-LD block on the home page" do
      get root_path

      expect(json_ld_blocks.pluck("@type")).to include("Person", "WebSite")
    end

    it "renders a canonical link on the home page" do
      get root_path

      expect(canonical_href).to be_present
    end

    it "renders a Person and a WebSite JSON-LD block on the about page too (not post-specific)" do
      get about_path

      expect(json_ld_blocks.pluck("@type")).to include("Person", "WebSite")
    end

    it "renders a canonical link on the about page" do
      get about_path

      expect(canonical_href).to be_present
    end

    it "every JSON-LD block on the home page parses as valid JSON (no invalid structured data)" do
      get root_path

      expect(json_ld_blocks).not_to be_empty
    end
  end

  describe "filtered index URLs canonicalize to the clean path (no query string)" do
    it "canonicalizes /writing?kind=note to /writing, stripping the query string" do # rubocop:disable RSpec/MultipleExpectations
      get posts_path(kind: "note")
      href = URI.parse(canonical_href)

      expect(href.query).to be_nil
      expect(href.path).to eq(posts_path)
    end

    it "canonicalizes /projects?status=Beta to /projects, stripping the query string" do # rubocop:disable RSpec/MultipleExpectations
      get projects_path(status: "Beta")
      href = URI.parse(canonical_href)

      expect(href.query).to be_nil
      expect(href.path).to eq(projects_path)
    end

    it "the unfiltered /writing canonical still points at its own clean path (baseline, not just filtered)" do
      get posts_path
      href = URI.parse(canonical_href)

      expect(href.path).to eq(posts_path)
    end
  end

  describe "GET /writing/:slug -- structured data and article meta" do
    let!(:post) do
      create(:post, slug: "seo-post", title: "SEO Post", tags: %w[ruby],
                    published_at: Time.zone.parse("2026-01-15T09:30:00Z"))
    end

    it "renders exactly three JSON-LD blocks: BlogPosting, Person, WebSite" do
      get post_path(slug: post.slug)

      expect(json_ld_blocks.pluck("@type")).to contain_exactly("BlogPosting", "Person", "WebSite")
    end

    it "the BlogPosting block's headline matches the real post title (no invalid structured data)" do
      get post_path(slug: post.slug)
      blog_posting = json_ld_blocks.find { |data| data["@type"] == "BlogPosting" }

      expect(blog_posting["headline"]).to eq("SEO Post")
    end

    it "sets og:type to article (not the layout's default website)" do
      get post_path(slug: post.slug)

      expect(meta_content("meta[property='og:type']")).to eq("article")
    end

    it "renders article:published_time meta as the post's published_at in ISO-8601" do
      get post_path(slug: post.slug)

      expect(meta_content("meta[property='article:published_time']")).to eq(post.published_at.iso8601)
    end

    it "renders article:author meta" do
      get post_path(slug: post.slug)

      expect(meta_content("meta[property='article:author']")).to eq("James Ebentier")
    end

    context "when the post has no image" do
      let!(:imageless_post) { create(:post, slug: "imageless-post", image: "") }

      it "resolves og:image to the branded og-default.png, not the bare root URL (pre-#1189 blank-image bug)" do
        get post_path(slug: imageless_post.slug)

        expect(meta_content("meta[property='og:image']")).to eq("#{root_url}og-default.png")
      end

      it "resolves twitter:image to the same branded default" do
        get post_path(slug: imageless_post.slug)

        expect(meta_content("meta[name='twitter:image']")).to eq("#{root_url}og-default.png")
      end

      it "never emits the bare root URL as an image" do
        get post_path(slug: imageless_post.slug)

        expect(meta_content("meta[property='og:image']")).not_to eq(root_url)
      end
    end

    context "when the post has an absolute external image" do
      let!(:external_image_post) do
        create(:post, slug: "external-image-post", image: "https://notmyrealemail.com/logo-120.png")
      end

      it "resolves og:image to the external URL unchanged, without doubling root_url (regression: 3ed5f5f)" do
        get post_path(slug: external_image_post.slug)

        expect(meta_content("meta[property='og:image']")).to eq("https://notmyrealemail.com/logo-120.png")
      end

      it "resolves twitter:image to the same external URL unchanged" do
        get post_path(slug: external_image_post.slug)

        expect(meta_content("meta[name='twitter:image']")).to eq("https://notmyrealemail.com/logo-120.png")
      end
    end
  end

  describe "footer social links and the Person sameAs stay in sync (single source of truth)" do
    it "the home footer's social links are exactly ApplicationHelper::SOCIAL_PROFILES' URLs, in order" do
      get root_path
      footer_social_links = response.parsed_body.at_css("footer").css("a[target='_blank']").pluck("href") -
                            [posts_url(format: "rss")]

      expect(footer_social_links).to eq(ApplicationHelper::SOCIAL_PROFILES.values)
    end

    it "the Person JSON-LD sameAs on that same page matches the footer's links exactly (can't drift)" do
      get root_path
      person = json_ld_blocks.find { |data| data["@type"] == "Person" }

      expect(person["sameAs"]).to eq(ApplicationHelper::SOCIAL_PROFILES.values)
    end
  end
end
