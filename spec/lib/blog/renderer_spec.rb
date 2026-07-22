# frozen_string_literal: true

require 'rails_helper'

# lib/blog/renderer.rb -- the Redcarpet HTML renderer backing BlogHelper#render_markdown
# (post/project markdown bodies). Exercised through the real render_markdown entry point
# (not the bare Renderer callbacks) so the `.html_safe` marking that makes the escaping
# actually matter in the rendered page is part of what these specs prove -- html_safe
# content is *not* re-escaped by ERB, so if `codespan` ever stopped escaping its input,
# render_markdown's own html_safe call would be exactly what lets a `<script>`/`<img
# onerror=...>` payload inside backticks execute instead of display, once a real view
# interpolates it (e.g. writing/show.html.erb's `<%= render_markdown(@post.content) %>`).
RSpec.describe Blog::Renderer do
  include BlogHelper

  describe "codespan escaping (XSS regression guard, PR review fix)" do
    it "escapes angle brackets in inline code so `Vec<T>` renders as text, not a real <T> element" do # rubocop:disable RSpec/MultipleExpectations
      html = render_markdown("Use `Vec<T>` here.")

      expect(html).to include("Vec&lt;T&gt;")
      expect(html).not_to include("Vec<T>")
    end

    it "escapes a malicious img/onerror payload inside backticks instead of emitting an executable tag" do # rubocop:disable RSpec/MultipleExpectations
      html = render_markdown("Payload: `<img src=x onerror=alert(1)>`")

      expect(html).to include("&lt;img src=x onerror=alert(1)&gt;")
      expect(html).not_to include("<img src=x onerror=alert(1)>")
    end

    it "keeps the code-chip's design-system CSS classes on the escaped <code> element" do
      html = render_markdown("Use `Vec<T>` here.")
      code = Nokogiri::HTML5.fragment(html).at_css("code")

      expect(code.classes).to include("bg-base-200", "border", "border-base-300", "rounded", "px-1.5", "py-0.5", "text-[0.9em]")
    end
  end

  describe "heading size mapping (article type-scale fidelity, PR review fix)" do
    it "keys a markdown '##' on the original level-2 (24px) class while demoting the element to <h3>" do # rubocop:disable RSpec/MultipleExpectations
      html = render_markdown("## Overview\nBody text")
      heading = Nokogiri::HTML5.fragment(html).at_css("h3")

      expect(heading.text).to eq("Overview")
      expect(heading.classes).to include("text-[24px]")
    end

    it "keys a markdown '###' on the original level-3 (19px) class while demoting the element to <h4>" do # rubocop:disable RSpec/MultipleExpectations
      html = render_markdown("### Details\nBody text")
      heading = Nokogiri::HTML5.fragment(html).at_css("h4")

      expect(heading.text).to eq("Details")
      expect(heading.classes).to include("text-[19px]")
    end
  end
end
