# frozen_string_literal: true

require 'rails_helper'

# GET /writing, /writing/:slug (R3, R5, R6) -- the Notes/Deep Dives content model's
# public-facing pages. Terminal-identity redesign (#1226) replaced the card-grid index with
# a directory-listing of rows (app/views/writing/index.html.erb) -- each row is a single
# `<a>` linking to the post, with an ISO date, a kind glyph (◆ deep_dive / ◇ note, with an
# sr-only kind_label), the title, the post's first tag as `#tag`, and the reading time in
# "<n> min" -- no more `.card`/`.badge`/`.btn-primary` markup, no more full tag list, no more
# "min read" wording. Post#reading_time (index row + show metadata) reads Post#content from
# disk; the factory default file_path points at a real public/blog fixture (#1201).
RSpec.describe 'Writing' do
  describe 'GET /writing' do
    # The listing container is the one stable structural hook the redesign kept for
    # "how many/which posts rendered" assertions -- each post row is a direct `<a>` child
    # of it (app/views/writing/index.html.erb).
    def post_rows
      response.parsed_body.at_css('div.border-t.border-base-300').css('a')
    end

    context 'when there are no posts' do
      it 'returns a successful response' do
        get posts_path

        expect(response).to have_http_status(:ok)
      end

      it 'renders no post rows' do
        get posts_path

        expect(post_rows).to be_empty
      end

      it 'still renders the kind-glyph legend footnote (static, not data-dependent)' do
        get posts_path

        expect(response.body).to include('deep dive', 'note')
      end
    end

    context 'when there are posts of mixed kind and publish date' do
      let!(:oldest_note) do
        create(:post, slug: 'oldest-note', kind: 'note', published_at: 3.days.ago)
      end
      let!(:middle_note) do
        create(:post, slug: 'middle-note', kind: 'note', published_at: 2.days.ago)
      end
      let!(:newest_deep_dive) do
        create(:post, slug: 'newest-deep-dive', kind: 'deep_dive', published_at: 1.day.ago)
      end

      before do
        create(:post, slug: 'future-post', kind: 'deep_dive', published_at: 1.day.from_now)
      end

      # Each row's title lives in its own `span.flex-1` (app/views/writing/index.html.erb) --
      # the one element per row that holds only the title, not the date/glyph/tag/min-read
      # text that also share the row's link text.
      def row_titles
        post_rows.map { |row| row.at_css('span.flex-1').text }
      end

      it 'renders one row per published post, excluding the unpublished future post' do
        get posts_path

        expect(post_rows.size).to eq(3)
      end

      it 'orders posts newest-published-first' do
        get posts_path

        expect(row_titles).to eq([newest_deep_dive.title, middle_note.title, oldest_note.title])
      end

      it 'filters to only Notes for ?kind=note' do
        get posts_path(kind: 'note')

        expect(row_titles).to contain_exactly(middle_note.title, oldest_note.title)
      end

      it 'filters to only Deep Dives for ?kind=deep_dive' do
        get posts_path(kind: 'deep_dive')

        expect(row_titles).to contain_exactly(newest_deep_dive.title)
      end

      it 'falls back to the unfiltered (all-kinds) list for an unrecognized ?kind= value -- not a 500, not empty' do
        get posts_path(kind: 'garbage')

        expect(post_rows.size).to eq(3)
      end
    end

    context 'with a single post row' do
      let!(:note) do
        create(
          :post,
          slug: 'a-real-note',
          title: 'A Real Note',
          kind: 'note',
          tags: %w[ruby rails],
          published_at: Time.zone.parse('2026-01-15')
        )
      end

      it "renders the post's title" do
        get posts_path

        expect(response.body).to include('A Real Note')
      end

      it 'renders the Note kind glyph with an sr-only kind label' do # rubocop:disable RSpec/MultipleExpectations
        get posts_path
        row = post_rows.find { |link| link.text.include?('A Real Note') }

        expect(row.at_css('span[aria-hidden="true"]').text).to eq(note.kind_glyph)
        expect(row.at_css('span.sr-only').text).to eq(note.kind_label)
      end

      it "renders the post's first tag as a #tag chip (only one tag is shown per row)" do # rubocop:disable RSpec/MultipleExpectations
        get posts_path

        expect(response.body).to include('#ruby')
        expect(response.body).not_to include('#rails')
      end

      it "renders the post's published date in ISO form" do
        get posts_path

        expect(response.body).to include('2026-01-15')
      end

      it "renders the post's reading time" do
        get posts_path

        expect(response.body).to include("#{note.reading_time} min")
      end

      it "links the row to the post's own show page" do
        get posts_path
        row = post_rows.find { |link| link.text.include?('A Real Note') }

        expect(row['href']).to eq(post_url(slug: note.slug))
      end
    end

    context 'with a Deep Dive post row' do
      let!(:deep_dive) { create(:post, slug: 'a-deep-dive', kind: 'deep_dive') }

      it 'renders the Deep Dive kind glyph, distinct from a Note row' do # rubocop:disable RSpec/MultipleExpectations
        get posts_path
        row = post_rows.find { |link| link.text.include?(deep_dive.title) }

        expect(row.at_css('span[aria-hidden="true"]').text).to eq('◆')
        expect(row.at_css('span.sr-only').text).to eq('Deep Dive')
      end
    end

    # Terminal-identity redesign (#1226) replaced the old "Note vs. Deep Dive" table/
    # editorial-heuristic sentence (that copy is retired -- see the design doc's Test
    # impact section) with a footnote explaining the two glyphs (app/views/writing/
    # index.html.erb). Covered for the empty-list case above; this proves the exact
    # wording survives with posts present too.
    it 'renders the glyph legend explaining ◆ (deep dive) vs. ◇ (note)' do
      get posts_path

      expect(response.body).to include(
        'deep dive — a worked-through system or argument',
        "note — a thought, reaction, or TIL. When in doubt, it's a note."
      )
    end
  end

  describe 'GET /writing/:slug' do
    let!(:post) do
      create(
        :post,
        slug: 'a-real-post',
        kind: 'note',
        excerpt: 'A short teaser for the article.',
        tags: %w[ruby],
        published_at: Time.zone.parse('2026-01-15')
      )
    end

    it 'returns a successful response for a real slug' do
      get post_path(slug: post.slug)

      expect(response).to have_http_status(:ok)
    end

    it 'renders the h1 with font-mono typography (R5)' do
      get post_path(slug: post.slug)

      expect(response.parsed_body.at_css('h1').classes).to include('font-mono')
    end

    # Copilot review fix (#1226, commit 705df34): the meta line used to carry BOTH a
    # decorative aria-hidden glyph AND a duplicate sr-only kind label, so screen readers
    # announced the kind twice. The glyph is now purely decorative (aria-hidden, no
    # sr-only twin) -- the visible "<kind> · date · N min" text right after it is what
    # conveys the kind to assistive tech.
    it 'renders the kind glyph as decorative and conveys the kind via the visible meta text (a11y fix, no duplicate sr-only label)' do # rubocop:disable RSpec/MultipleExpectations
      get post_path(slug: post.slug)
      meta = response.parsed_body.at_css('article p')

      expect(meta.at_css('span[aria-hidden="true"]').text).to eq(post.kind_glyph)
      expect(meta.at_css('span.sr-only')).to be_nil
      expect(meta.text).to include(post.kind_label.downcase)
    end

    it 'renders the tags inline in the meta line, each prefixed with #' do
      get post_path(slug: post.slug)

      expect(response.parsed_body.at_css('article p').text).to include('#ruby')
    end

    it 'renders the excerpt as the dek beneath the h1' do
      get post_path(slug: post.slug)

      expect(response.body).to include('A short teaser for the article.')
    end

    it 'renders the published date in ISO form' do
      get post_path(slug: post.slug)

      expect(response.parsed_body.at_css('article p').text).to include('2026-01-15')
    end

    it 'renders the reading time' do
      get post_path(slug: post.slug)

      expect(response.parsed_body.at_css('article p').text).to include("#{post.reading_time} min")
    end

    it 'returns 404 for an unknown slug' do
      get post_path(slug: 'no-such-slug')

      expect(response).to have_http_status(:not_found)
    end

    context 'when the post has a medium_url (#1185)' do
      let!(:syndicated_post) do
        create(:post, :with_medium_url, slug: 'syndicated-post')
      end

      it 'renders the "Also on Medium" link' do
        get post_path(slug: syndicated_post.slug)

        expect(response.parsed_body.at_css('a[href="https://medium.com/p/example-post"]')).to be_present
      end

      it 'renders the "Also on Medium" link with target="_blank"' do
        get post_path(slug: syndicated_post.slug)

        expect(response.parsed_body.at_css('a[href="https://medium.com/p/example-post"]')['target']).to eq('_blank')
      end

      it 'renders the "Also on Medium" link with rel="noopener noreferrer"' do
        get post_path(slug: syndicated_post.slug)

        expect(response.parsed_body.at_css('a[href="https://medium.com/p/example-post"]')['rel']).to eq('noopener noreferrer')
      end
    end

    context 'when the post has no medium_url (#1185)' do
      it 'does not render an "Also on Medium" link' do
        get post_path(slug: post.slug)

        expect(response.parsed_body.at_css('a[href*="medium.com"]')).to be_nil
      end
    end
  end

  describe 'GET /writing.rss' do
    it 'returns a successful response' do
      get posts_path(format: :rss)

      expect(response).to have_http_status(:ok)
    end

    it 'returns application/rss+xml' do
      get posts_path(format: :rss)

      expect(response.media_type).to eq('application/rss+xml')
    end

    it 'points the channel link at the writing index' do
      get posts_path(format: :rss)

      channel_link = Nokogiri::XML(response.body).at('channel > link').text
      expect(channel_link).to eq(posts_url)
    end

    it 'points the channel image link at the writing index' do
      get posts_path(format: :rss)

      image_link = Nokogiri::XML(response.body).at('channel image link').text
      expect(image_link).to eq(posts_url)
    end

    it 'does not include the pre-existing leadning typo in the channel description' do
      get posts_path(format: :rss)

      expect(response.body).not_to include('leadning')
    end

    it 'uses learning in the channel description' do
      get posts_path(format: :rss)

      expect(response.body).to include('learning')
    end
  end

  describe 'GET /blog (retired route -- D2/R3, no redirect)' do
    it 'no longer resolves -- returns 404, not a redirect' do
      get '/blog'

      expect(response).to have_http_status(:not_found)
    end

    it 'does not redirect (no Location header)' do
      get '/blog'

      expect(response).not_to be_redirect
    end
  end

  describe 'GET /blog/:slug (retired route)' do
    it 'no longer resolves -- returns 404' do
      get '/blog/some-post'

      expect(response).to have_http_status(:not_found)
    end
  end
end
