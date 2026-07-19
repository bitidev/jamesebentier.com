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
end
