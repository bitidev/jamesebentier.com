# frozen_string_literal: true

require 'rails_helper'

# GET /writing, /writing/:slug (R3, R5, R6) -- the Notes/Deep Dives content model's
# public-facing pages, migrated onto the shared components/_section/_card/_pill/_cta_button
# partials (R6), mirroring spec/requests/projects_spec.rb's own real-controller/view-stack
# style (see adlc/methods/code-quality/call-site-wiring-verification.md). Post#reading_time
# (index card + show metadata) reads Post#content from disk; the factory default file_path
# points at a real public/blog fixture (#1201).
RSpec.describe 'Writing' do
  describe 'GET /writing' do
    context 'when there are no posts' do
      it 'returns a successful response' do
        get posts_path

        expect(response).to have_http_status(:ok)
      end

      it 'renders no post cards' do
        get posts_path

        expect(response.parsed_body.css('.card')).to be_empty
      end

      it 'still renders the editorial guidelines section (static, not data-dependent) (D9)' do
        get posts_path

        expect(response.body).to include('Note vs. Deep Dive')
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

      it 'renders one card per published post, excluding the unpublished future post' do
        get posts_path

        expect(response.parsed_body.css('.card').size).to eq(3)
      end

      it 'orders posts newest-published-first' do
        get posts_path
        titles = response.parsed_body.css('.card-title').map(&:text)

        expect(titles).to eq([newest_deep_dive.title, middle_note.title, oldest_note.title])
      end

      it 'filters to only Notes for ?kind=note' do
        get posts_path(kind: 'note')
        titles = response.parsed_body.css('.card-title').map(&:text)

        expect(titles).to contain_exactly(middle_note.title, oldest_note.title)
      end

      it 'filters to only Deep Dives for ?kind=deep_dive' do
        get posts_path(kind: 'deep_dive')
        titles = response.parsed_body.css('.card-title').map(&:text)

        expect(titles).to contain_exactly(newest_deep_dive.title)
      end

      it 'falls back to the unfiltered (all-kinds) list for an unrecognized ?kind= value -- not a 500, not empty' do
        get posts_path(kind: 'garbage')

        expect(response.parsed_body.css('.card').size).to eq(3)
      end
    end

    context 'with a single post card' do
      let!(:note) do
        create(
          :post,
          slug: 'a-real-note',
          title: 'A Real Note',
          kind: 'note',
          excerpt: 'A short teaser for the note.',
          tags: %w[ruby rails],
          published_at: Time.zone.parse('2026-01-15')
        )
      end

      it "renders the post's title" do
        get posts_path

        expect(response.body).to include('A Real Note')
      end

      it 'renders the Note kind badge with the badge-info role (D7)' do
        get posts_path
        badge = response.parsed_body.css('.badge').find { |element| element.text == 'Note' }

        expect(badge.classes).to include('badge-info')
      end

      it 'renders one tag pill per tag' do
        get posts_path
        tag_texts = response.parsed_body.css('.badge-outline').map(&:text)

        expect(tag_texts).to contain_exactly('ruby', 'rails')
      end

      it "renders the post's excerpt" do
        get posts_path

        expect(response.body).to include('A short teaser for the note.')
      end

      it "renders the post's published date" do
        get posts_path

        expect(response.body).to include('January 15, 2026')
      end

      it "renders the post's reading time" do
        get posts_path

        expect(response.body).to include("#{note.reading_time} min read")
      end

      it "links the CTA button to the post's own show page" do
        get posts_path
        cta = response.parsed_body.at_css('.btn-primary')

        expect(URI.parse(cta['href']).path).to eq(post_path(slug: note.slug))
      end
    end

    context 'with a Deep Dive post card' do
      before { create(:post, slug: 'a-deep-dive', kind: 'deep_dive') }

      it 'renders the Deep Dive kind badge with the badge-accent role (D7)' do
        get posts_path
        badge = response.parsed_body.css('.badge').find { |element| element.text == 'Deep Dive' }

        expect(badge.classes).to include('badge-accent')
      end
    end

    it 'renders the Note vs. Deep Dive editorial guidelines table (R6, D9)' do
      get posts_path
      guidelines = response.parsed_body.css('section').find { |section| section.at_css('h2')&.text == 'Note vs. Deep Dive' }

      expect(guidelines.at_css('table')).to be_present
    end

    it 'renders the editorial heuristic sentence verbatim (R6)' do
      get posts_path

      expect(response.body).to include('Notes can graduate into Deep Dives')
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

    it 'renders the kind badge' do
      get post_path(slug: post.slug)
      badge = response.parsed_body.css('.badge').find { |element| element.text == 'Note' }

      expect(badge.classes).to include('badge-info')
    end

    it 'renders the tag pills' do
      get post_path(slug: post.slug)

      expect(response.parsed_body.css('.badge-outline').map(&:text)).to include('ruby')
    end

    it 'renders the excerpt' do
      get post_path(slug: post.slug)

      expect(response.body).to include('A short teaser for the article.')
    end

    it 'renders the published date' do
      get post_path(slug: post.slug)

      expect(response.body).to include('January 15, 2026')
    end

    it 'renders the reading time' do
      get post_path(slug: post.slug)

      expect(response.body).to include("#{post.reading_time} min read")
    end

    it 'returns 404 for an unknown slug' do
      get post_path(slug: 'no-such-slug')

      expect(response).to have_http_status(:not_found)
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
