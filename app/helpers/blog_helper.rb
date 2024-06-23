# frozen_string_literal: true

require 'blog/renderer'

module BlogHelper # rubocop:disable Style/Documentation
  def render_markdown(content)
    markdown = Redcarpet::Markdown.new(Blog::Renderer, autolink: true, tables: true)
    markdown.render(content).html_safe # rubocop:disable Rails/OutputSafety
  end
end
