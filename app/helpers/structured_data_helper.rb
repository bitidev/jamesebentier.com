# frozen_string_literal: true

# Emits schema.org JSON-LD <script> blocks (#1189 design doc). Each entity is its own
# application/ld+json script tag rather than one @graph -- valid either way, but the
# per-entity form is what Google's Rich Results tooling prefers.
#
# XSS-safety is mandatory here: `headline`/`description`/`keywords` ultimately come from
# Post#title/#description/#tags, which are free-text content, not app-controlled strings.
# A value containing "</script>", "<", ">", or "&" must not be able to break out of the
# script context and inject markup into the page. The hashes below are built as plain
# Ruby data (never string-interpolated into HTML) and serialized via #to_json, then passed
# through Rails' `json_escape` (ERB::Util.json_escape) before being wrapped in `raw` --
# json_escape rewrites the JSON-unsafe-in-HTML characters (< > & U+2028 U+2029) to \uXXXX
# escapes, which are valid inside a JSON string and inert as HTML/script markup.
module StructuredDataHelper
  # Filename of the static branded OG default (lib/tasks/og_image.rake is its sole
  # producer). Kept here as the single place that names it for JSON-LD/image-fallback
  # purposes; the layout's display_meta_tags default spells out the same path literally.
  OG_DEFAULT_IMAGE_FILENAME = "og-default.png"

  def person_json_ld # rubocop:disable Metrics/MethodLength
    json_ld_script(
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => "James Ebentier",
      "jobTitle" => "Software Architect",
      "address" => {
        "@type" => "PostalAddress",
        "addressLocality" => "Berlin",
        "addressCountry" => "DE"
      },
      "url" => root_url,
      "image" => og_default_image_url,
      "sameAs" => ApplicationHelper::SOCIAL_PROFILES.values
    )
  end

  def website_json_ld
    json_ld_script(
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => t("site.name"),
      "url" => root_url
    )
  end

  def blog_posting_json_ld(post) # rubocop:disable Metrics/MethodLength
    published = post.published_at.iso8601

    json_ld_script(
      "@context" => "https://schema.org",
      "@type" => "BlogPosting",
      "headline" => post.title,
      "description" => post.description,
      "datePublished" => published,
      "dateModified" => published,
      "author" => {
        "@type" => "Person",
        "name" => "James Ebentier",
        "url" => root_url
      },
      "keywords" => post.tags,
      "mainEntityOfPage" => post_url(post.slug),
      "url" => post_url(post.slug),
      "image" => resolved_og_image(post),
      "wordCount" => post.content.split.size,
      "timeRequired" => "PT#{post.reading_time}M"
    )
  end

  # Matches an already-absolute http(s) URL -- some seeded Post#image values are full
  # external URLs (see db/seeds.rb, e.g. "https://notmyrealemail.com/logo-120.png"), not
  # site-relative paths, so blindly prefixing root_url would double up into a broken
  # "https://jamesebentier.com/https://...". This distinguishes the two cases.
  ABSOLUTE_URL = %r{\Ahttps?://}i

  # Resolves the OG/Twitter/JSON-LD image for a post -- the single place this fallback is
  # decided, shared by blog_posting_json_ld above and writing/show's own set_meta_tags
  # og/twitter image, so all three can never disagree:
  #   - blank Post#image -> the site-wide branded default (fixes the pre-#1189 bug where a
  #     post without an image emitted the bare root URL, "https://jamesebentier.com/", as
  #     its og:image);
  #   - an already-absolute Post#image (some seed data stores a full external URL, see
  #     ABSOLUTE_URL above) -> used verbatim, never re-prefixed with root_url;
  #   - a site-relative Post#image (e.g. "blog/images/foo.png") -> root_url-prefixed.
  def resolved_og_image(post)
    return og_default_image_url if post.image.blank?
    return post.image if post.image.match?(ABSOLUTE_URL)

    "#{root_url}#{post.image}"
  end

  private

  def og_default_image_url
    "#{root_url}#{OG_DEFAULT_IMAGE_FILENAME}"
  end

  # json_escape (ERB::Util.json_escape) has already neutralized every HTML-significant
  # character in the JSON string (see the module comment above) -- html_safe is correct
  # here, not a shortcut around it. Same pattern/justification as BlogHelper#render_markdown.
  def json_ld_script(hash)
    content_tag(:script, raw(json_escape(hash.to_json)), type: "application/ld+json") # rubocop:disable Rails/OutputSafety
  end
end
