# frozen_string_literal: true

require "rails_helper"

# app/helpers/structured_data_helper.rb (#1189 design doc) -- JSON-LD <script> blocks for
# Person/WebSite/BlogPosting, plus resolved_og_image, the single place the OG/Twitter/
# JSON-LD image fallback is decided. Every assertion here parses the emitted JSON and checks
# real keys/values -- never just "the string is present" -- and the XSS section proves the
# json_escape defense the module comment promises actually holds against free-text Post
# content, not app-controlled strings.
RSpec.describe StructuredDataHelper do
  def json_ld_from(html)
    node = Nokogiri::HTML.fragment(html).at_css('script[type="application/ld+json"]')
    JSON.parse(node.text)
  end

  describe "#person_json_ld" do
    it "renders a script[type=application/ld+json] tag" do
      html = helper.person_json_ld

      expect(Nokogiri::HTML.fragment(html).at_css('script[type="application/ld+json"]')).to be_present
    end

    it "emits a valid schema.org Person with name/jobTitle/url" do # rubocop:disable RSpec/ExampleLength
      data = json_ld_from(helper.person_json_ld)

      expect(data).to include(
        "@context" => "https://schema.org",
        "@type" => "Person",
        "name" => "James Ebentier",
        "jobTitle" => "Software Architect",
        "url" => helper.root_url
      )
    end

    it "sameAs equals ApplicationHelper::SOCIAL_PROFILES' URLs exactly -- the single source of truth" do
      data = json_ld_from(helper.person_json_ld)

      expect(data["sameAs"]).to eq(ApplicationHelper::SOCIAL_PROFILES.values)
    end
  end

  describe "#website_json_ld" do
    it "emits a valid schema.org WebSite with the site name and root url" do # rubocop:disable RSpec/ExampleLength
      data = json_ld_from(helper.website_json_ld)

      expect(data).to include(
        "@context" => "https://schema.org",
        "@type" => "WebSite",
        "name" => "JEB Development",
        "url" => helper.root_url
      )
    end
  end

  describe "#blog_posting_json_ld" do
    let(:post) do
      create(
        :post,
        title: "A Real Post",
        description: "A real description of the post",
        tags: %w[ruby rails],
        published_at: Time.zone.parse("2026-01-15T10:00:00Z")
      )
    end

    it "emits a valid schema.org BlogPosting with headline/description/keywords" do # rubocop:disable RSpec/ExampleLength
      data = json_ld_from(helper.blog_posting_json_ld(post))

      expect(data).to include(
        "@context" => "https://schema.org",
        "@type" => "BlogPosting",
        "headline" => "A Real Post",
        "description" => "A real description of the post",
        "keywords" => %w[ruby rails]
      )
    end

    it "sets datePublished to the post's published_at in real ISO-8601" do
      data = json_ld_from(helper.blog_posting_json_ld(post))

      expect(data["datePublished"]).to eq(post.published_at.iso8601)
    end

    it "nests author as a Person reference, not a bare name string" do
      data = json_ld_from(helper.blog_posting_json_ld(post))

      expect(data["author"]).to eq("@type" => "Person", "name" => "James Ebentier", "url" => helper.root_url)
    end

    it "sets mainEntityOfPage to the post's own canonical URL" do
      data = json_ld_from(helper.blog_posting_json_ld(post))

      expect(data["mainEntityOfPage"]).to eq(helper.post_url(post.slug))
    end

    it "sets wordCount from the real post content, not a placeholder" do
      data = json_ld_from(helper.blog_posting_json_ld(post))

      expect(data["wordCount"]).to eq(post.content.split.size)
    end

    it "sets timeRequired as an ISO-8601 duration matching the post's reading_time in minutes" do
      data = json_ld_from(helper.blog_posting_json_ld(post))

      expect(data["timeRequired"]).to eq("PT#{post.reading_time}M")
    end

    context "when the post has no image" do
      let(:imageless_post) { create(:post, slug: "imageless-post", image: "") }

      it "resolves image to the branded default, matching resolved_og_image" do # rubocop:disable RSpec/MultipleExpectations
        data = json_ld_from(helper.blog_posting_json_ld(imageless_post))

        expect(data["image"]).to eq(helper.resolved_og_image(imageless_post))
        expect(data["image"]).to end_with("/og-default.png")
      end
    end

    # XSS regression (#1189 design doc): headline/description/keywords come from
    # Post#title/#description/#tags, which are free-text content a post author controls, not
    # an app-controlled string. A value containing "</script>", "<", ">", or "&" must not be
    # able to break out of the script context.
    context "when title/description contain script-breakout and HTML-significant characters (XSS regression)" do
      let(:malicious_post) do
        create(
          :post,
          slug: "xss-post",
          title: "</script><script>alert(1)</script>",
          description: "Rock & Roll < 100% > 0%"
        )
      end

      it "emits exactly one literal </script> in the rendered block -- the real closing tag, not an injected one" do
        html = helper.blog_posting_json_ld(malicious_post)

        expect(html.scan("</script>").size).to eq(1)
      end

      it "does not leak a literal unescaped < or > from the malicious title/description into the markup" do
        html = helper.blog_posting_json_ld(malicious_post)
        # Only the wrapping <script type="application/ld+json"> and its closing </script>
        # tag are legitimate -- both of those literal angle-bracket occurrences are
        # accounted for below, so this counts every OTHER occurrence, which must be zero.
        inner = html.delete_prefix('<script type="application/ld+json">').delete_suffix("</script>")

        expect(inner).not_to include("<", ">")
      end

      it "still round-trips to the exact original title/description via JSON.parse (proves it's escaped, not corrupted)" do # rubocop:disable RSpec/MultipleExpectations
        data = json_ld_from(helper.blog_posting_json_ld(malicious_post))

        expect(data["headline"]).to eq("</script><script>alert(1)</script>")
        expect(data["description"]).to eq("Rock & Roll < 100% > 0%")
      end
    end
  end

  describe "#resolved_og_image" do
    it "falls back to the branded site-wide default when Post#image is blank" do
      post = create(:post, image: "")

      expect(helper.resolved_og_image(post)).to eq("#{helper.root_url}og-default.png")
    end

    it "uses an already-absolute http(s) Post#image verbatim (regression: 3ed5f5f)" do
      post = create(:post, image: "https://notmyrealemail.com/logo-120.png")

      expect(helper.resolved_og_image(post)).to eq("https://notmyrealemail.com/logo-120.png")
    end

    it "never doubles root_url onto an absolute image (regression: 3ed5f5f -- guards the exact bug)" do
      post = create(:post, image: "https://notmyrealemail.com/logo-120.png")

      expect(helper.resolved_og_image(post)).not_to eq("#{helper.root_url}https://notmyrealemail.com/logo-120.png")
    end

    it "root_url-prefixes a site-relative Post#image" do
      post = create(:post, image: "blog/images/foo.png")

      expect(helper.resolved_og_image(post)).to eq("#{helper.root_url}blog/images/foo.png")
    end

    it "never resolves to the bare root URL for a blank image (pre-#1189 regression guard)" do
      post = create(:post, image: "")

      expect(helper.resolved_og_image(post)).not_to eq(helper.root_url)
    end
  end
end
