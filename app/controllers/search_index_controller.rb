# frozen_string_literal: true

# GET /search-index.json (spec R9, docs/specs/1187-modal-vim-keyboard-navigation.md) --
# SEARCH mode's (spec R7) content index: a plain-text-fields-only JSON serialization of
# every Post.published and Project record, fetched lazily and cached client-side for the
# rest of the tab session by app/javascript/keyboard_nav/search_index.js. Never renders
# rendered-HTML body content (Post#content/Project#content) -- title/description/tags
# only, per Decision 3's rationale.
class SearchIndexController < ApplicationController
  def index
    items = Post.published.map { |post| serialize_post(post) } + Project.all.map { |project| serialize_project(project) }

    render json: items
  end

  private

  # `excerpt` is a real, always-present, presence-validated Post column as of P1.4/#1183
  # (docs/specs/1183-writing-redesign-notes-deep-dives.md D6/R9) -- description remains a
  # separate concern (the meta-tag/SEO field), not a fallback for this index anymore.
  def serialize_post(post)
    { title: post.title, url: post_url(slug: post.slug), excerpt: post.excerpt, tags: post.tags, type: "post" }
  end

  # Project has no excerpt/tags equivalent today: description (already present) truncated
  # to a short excerpt length for consistency with the Post side; tags: [] (R9).
  def serialize_project(project)
    { title: project.title, url: project_url(slug: project.slug), excerpt: project.description.truncate(160), tags: [], type: "project" }
  end
end
