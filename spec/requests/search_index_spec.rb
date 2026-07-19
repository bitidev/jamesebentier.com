# frozen_string_literal: true

require 'rails_helper'

# GET /search-index.json (#1187 R9, docs/specs/1187-modal-vim-keyboard-navigation.md) --
# SEARCH mode's content index. Proves the documented item shape (title/url/excerpt/tags/
# type), the Post.published scope (unpublished/future posts never leak into the index),
# and the excerpt fallback: Post has no `excerpt` column in this worktree today (verified
# directly against app/models/post.rb), so every Post item's excerpt sources from
# Post#description instead -- the fallback branch this spec exercises, per R9's explicit
# "cross-issue dependency check performed and documented" acceptance criterion (Increment
# 4). Project has no excerpt/tags equivalent; its item uses a truncated #description and
# tags: [].
RSpec.describe 'GET /search-index.json' do
  it 'responds with a successful JSON response' do # rubocop:disable RSpec/MultipleExpectations
    get search_index_path

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('application/json')
  end

  it 'returns an empty array when there is no content' do
    get search_index_path

    expect(response.parsed_body).to eq([])
  end

  context 'with a published post' do
    let!(:post) do
      create(
        :post,
        slug: 'hosting-your-personal-site',
        title: 'Hosting Your Personal Site',
        description: 'A guide to static hosting on S3',
        tags: %w[aws cloud],
        published_at: 1.day.ago
      )
    end

    it "serializes the post's item shape exactly, falling back to description for excerpt (R9)" do # rubocop:disable RSpec/ExampleLength
      get search_index_path

      items = response.parsed_body

      expect(items).to contain_exactly(
        {
          'title' => 'Hosting Your Personal Site',
          'url' => post_url(slug: post.slug),
          'excerpt' => 'A guide to static hosting on S3',
          'tags' => %w[aws cloud],
          'type' => 'post',
        }
      )
    end

    it 'confirms Post has no excerpt column yet, so the fallback branch is genuinely exercised' do
      expect(post).not_to have_attribute(:excerpt)
    end
  end

  context 'with an unpublished (future-dated) post' do
    let!(:draft_post) { create(:post, slug: 'not-yet-live', published_at: 1.day.from_now) }

    it 'excludes it from the index (Post.published scope)' do
      get search_index_path

      titles = response.parsed_body.pluck('title')

      expect(titles).not_to include(draft_post.title)
    end
  end

  context 'with a project' do
    let!(:project) do
      create(
        :project,
        slug: 'vimium-clone',
        title: 'Vimium Clone',
        description: 'A' * 200
      )
    end

    it 'serializes the project with tags: [], a truncated description excerpt, and type "project"' do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      get search_index_path

      item = response.parsed_body.find { |entry| entry['type'] == 'project' }

      expect(item['title']).to eq('Vimium Clone')
      expect(item['url']).to eq(project_url(slug: project.slug))
      expect(item['tags']).to eq([])
      expect(item['excerpt'].length).to be <= 160
      expect(item['excerpt']).to start_with('A' * 20)
    end
  end

  context 'with both a post and a project' do
    before do
      create(:post, slug: 'a-post')
      create(:project, slug: 'a-project')
    end

    it 'includes one item per record' do
      get search_index_path

      expect(response.parsed_body.size).to eq(2)
    end
  end
end
