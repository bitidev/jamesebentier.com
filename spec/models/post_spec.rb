# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Post do
  describe 'schema and validations' do
    before { create(:post) }

    # ID
    it { is_expected.to have_db_column(:id).of_type(:uuid) }

    # Slug
    it { is_expected.to have_db_column(:slug).of_type(:string).with_options(limit: 255, null: false) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug).case_insensitive }

    # Title
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(limit: 1024, null: false) }
    it { is_expected.to validate_presence_of(:title) }

    # Description
    it { is_expected.to have_db_column(:description).of_type(:string).with_options(limit: 1024, null: false) }
    it { is_expected.to validate_presence_of(:description) }

    # Keywords
    it { is_expected.to have_db_column(:keywords).of_type(:string).with_options(limit: 1024, null: false) }
    it { is_expected.to validate_presence_of(:keywords) }

    # Image
    it { is_expected.to have_db_column(:image).of_type(:string).with_options(limit: 1024, null: false, default: "") }

    # Tags
    it { is_expected.to have_db_column(:tags).of_type(:json).with_options(null: false, default: []) }

    # File Path
    it { is_expected.to have_db_column(:file_path).of_type(:string).with_options(limit: 1024, null: false) }
    it { is_expected.to validate_presence_of(:file_path) }

    # Published At
    it { is_expected.to have_db_column(:published_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to validate_presence_of(:published_at) }

    # Featured
    it { is_expected.to have_db_column(:featured).of_type(:boolean).with_options(null: false, default: false) }

    # Kind (P1.4/#1183 R1/D3)
    it { is_expected.to have_db_column(:kind).of_type(:string).with_options(limit: 20, null: false, default: 'deep_dive') }
    it { is_expected.to validate_inclusion_of(:kind).in_array(Post::KINDS) }

    # Excerpt (P1.4/#1183 R1/D4)
    it { is_expected.to have_db_column(:excerpt).of_type(:string).with_options(limit: 280, null: false, default: '') }
    it { is_expected.to validate_presence_of(:excerpt) }
  end

  # Post.featured / Post.for_home (1181 R2) -- curated-first, chronological-fallback, always
  # scoped under `published` first. Deliberately nested outside the "schema and validations"
  # group above (no `before { create(:post) }` in scope here) so these behavioral tests control
  # every row in the table themselves.
  describe '.featured' do
    it 'returns only the posts flagged featured' do
      featured_post = create(:post, slug: 'featured-post', featured: true)
      create(:post, slug: 'unfeatured-post', featured: false)

      expect(described_class.featured).to contain_exactly(featured_post)
    end
  end

  describe '.for_home' do
    it 'prefers the curated (featured) set over the chronological fallback when some posts are featured' do
      featured_post = create(:post, slug: 'featured-post', featured: true, published_at: 2.days.ago)
      create(:post, slug: 'unfeatured-post', featured: false, published_at: 1.day.ago)

      expect(described_class.for_home.to_a).to eq([featured_post])
    end

    it 'falls back to the most recently published posts, newest first, when none are featured' do
      oldest = create(:post, slug: 'oldest-post', published_at: 3.days.ago)
      middle = create(:post, slug: 'middle-post', published_at: 2.days.ago)
      newest = create(:post, slug: 'newest-post', published_at: 1.day.ago)

      expect(described_class.for_home.to_a).to eq([newest, middle, oldest])
    end

    it 'respects the limit argument, returning only that many posts even when more are available' do
      5.times { |i| create(:post, slug: "post-#{i}", published_at: i.days.ago) }

      expect(described_class.for_home(limit: 2).size).to eq(2)
    end

    it 'never surfaces an unpublished (future-dated) post, even when it is featured' do
      create(:post, slug: 'future-featured-post', featured: true, published_at: 1.day.from_now)
      published_post = create(:post, slug: 'current-post', featured: false, published_at: 1.day.ago)

      expect(described_class.for_home.to_a).to eq([published_post])
    end
  end

  # Whitelisted filter (R2/D10): garbage/blank input must fall back to `all`, never raise
  # and never silently return an empty relation. Four explicit cases, per the spec's own
  # Testing Strategy note -- not just the happy path.
  describe '.by_kind' do
    let!(:note_post) { create(:post, slug: 'a-note', kind: 'note') }
    let!(:deep_dive_post) { create(:post, slug: 'a-deep-dive', kind: 'deep_dive') }

    it 'returns only Note posts for "note"' do
      expect(described_class.by_kind('note')).to contain_exactly(note_post)
    end

    it 'returns only Deep Dive posts for "deep_dive"' do
      expect(described_class.by_kind('deep_dive')).to contain_exactly(deep_dive_post)
    end

    it 'returns every post, unfiltered, for a nil kind' do
      expect(described_class.by_kind(nil)).to contain_exactly(note_post, deep_dive_post)
    end

    it 'returns every post, unfiltered, for a blank kind' do
      expect(described_class.by_kind('')).to contain_exactly(note_post, deep_dive_post)
    end

    it 'returns every post, unfiltered, for an unrecognized kind -- not an empty relation, not a raise' do
      expect(described_class.by_kind('garbage')).to contain_exactly(note_post, deep_dive_post)
    end
  end

  describe '#kind_label' do
    it 'labels "note" as "Note"' do
      expect(build(:post, kind: 'note').kind_label).to eq('Note')
    end

    it 'labels "deep_dive" as "Deep Dive"' do
      expect(build(:post, kind: 'deep_dive').kind_label).to eq('Deep Dive')
    end
  end

  # Computed, not stored (D5) -- Post#content is stubbed here to isolate the word-count/
  # ceiling/minimum-1 math from the real, uncached disk read (the filesystem is an external
  # boundary per the test-audit mock-boundary rules), so these boundary cases stay
  # deterministic and independent of any real markdown file's word count ever changing.
  describe '#reading_time' do
    it 'returns exactly 1 for a word count that is an exact multiple of 200 (a full, non-rounded-up minute)' do
      post = build(:post)
      allow(post).to receive(:content).and_return((['word'] * 200).join(' '))

      expect(post.reading_time).to eq(1)
    end

    it 'rounds up to the next minute for a word count just over a 200-word boundary' do
      post = build(:post)
      allow(post).to receive(:content).and_return((['word'] * 201).join(' '))

      expect(post.reading_time).to eq(2)
    end

    it 'never returns less than 1, even for empty content' do
      post = build(:post)
      allow(post).to receive(:content).and_return('')

      expect(post.reading_time).to eq(1)
    end

    it 'computes from the real on-disk markdown body via the real, unstubbed #content (wiring check)' do
      post = create(:post, file_path: '2024-06-17-Why-Is-Automated-Testing-Important.md')

      # This fixture's body (front matter stripped) is 540 words -- ceil(540 / 200.0) = 3.
      # A hardcoded expectation (not a recomputed copy of the implementation's own formula)
      # so this test still fails if the ceiling/word-count math regresses.
      expect(post.reading_time).to eq(3)
    end
  end

  # Idempotent backfill (D4) -- update_column bypasses validation to simulate the real
  # pre-existing-row state the ADD COLUMN's own DB-level default produces (a validated
  # `create` can never itself produce a blank `excerpt`, since presence is validated).
  describe '.backfill_excerpt_from_description!' do
    it 'sets the excerpt from a truncated description when the excerpt is blank' do
      post = create(:post, slug: 'blank-excerpt', description: 'A' * 300)
      post.update_column(:excerpt, '') # rubocop:disable Rails/SkipsModelValidations

      described_class.backfill_excerpt_from_description!

      expect(post.reload.excerpt).to eq(('A' * 300).truncate(280))
    end

    it 'leaves an already-set, distinct excerpt untouched on a second invocation (idempotent)' do
      post = create(:post, slug: 'real-excerpt', description: 'The full SEO description', excerpt: 'A real hand-written excerpt')

      described_class.backfill_excerpt_from_description!

      expect(post.reload.excerpt).to eq('A real hand-written excerpt')
    end

    it 'leaves posts with no blank excerpt at all untouched' do
      other_post = create(:post, slug: 'untouched-post', description: 'Some description', excerpt: 'Its own real excerpt')

      expect { described_class.backfill_excerpt_from_description! }.not_to(change { other_post.reload.excerpt })
    end
  end
end
