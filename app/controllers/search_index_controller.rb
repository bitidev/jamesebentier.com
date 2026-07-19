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

  # `excerpt` sources from Post#excerpt only if that column exists at implementation time
  # (P1.4 -- verified directly against app/models/post.rb, not yet shipped in this
  # worktree); otherwise it falls back to Post#description, already present/required and
  # similar in purpose (a one-sentence SEO description). A single has_attribute? branch,
  # not two code paths to maintain -- when P1.4 ships Post#excerpt, this branch simply
  # stops firing, no shape change (R9).
  def serialize_post(post)
    excerpt = post.has_attribute?(:excerpt) ? post.excerpt : post.description

    { title: post.title, url: post_url(slug: post.slug), excerpt: excerpt, tags: post.tags, type: "post" }
  end

  # Project has no excerpt/tags equivalent today: description (already present) truncated
  # to a short excerpt length for consistency with the Post side; tags: [] (R9).
  def serialize_project(project)
    { title: project.title, url: project_url(slug: project.slug), excerpt: project.description.truncate(160), tags: [], type: "project" }
  end
end
