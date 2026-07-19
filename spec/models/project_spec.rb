# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project do
  describe 'schema and validations' do
    before { create(:project) }

    # ID
    it { is_expected.to have_db_column(:id).of_type(:uuid) }

    # Slug
    it { is_expected.to have_db_column(:slug).of_type(:string).with_options(limit: 255, null: false) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug) }

    # Title
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(limit: 1024, null: false) }
    it { is_expected.to validate_presence_of(:title) }

    # Status
    it { is_expected.to have_db_column(:status).of_type(:string).with_options(limit: 255, null: false, default: 'Beta') }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[Pre-Launch Beta Live]) }

    # URL
    it { is_expected.to have_db_column(:url).of_type(:string).with_options(limit: 1024, null: false) }
    it { is_expected.to validate_presence_of(:url) }

    # Image
    it { is_expected.to have_db_column(:image).of_type(:string).with_options(limit: 1024, null: false) }
    it { is_expected.to validate_presence_of(:image) }

    # Description
    it { is_expected.to have_db_column(:description).of_type(:text).with_options(limit: nil, null: false) }
    it { is_expected.to validate_presence_of(:description) }

    # Featured
    it { is_expected.to have_db_column(:featured).of_type(:boolean).with_options(null: false, default: false) }

    # Read / Source (optional triple-link legs -- see docs/specs/1182-projects-page-redesign.md R1).
    # `url` above remains the one required "demo" leg; these two are additive and nullable.
    it { is_expected.to have_db_column(:read_url).of_type(:string).with_options(limit: 1024, null: true) }
    it { is_expected.not_to validate_presence_of(:read_url) }
    it { is_expected.to have_db_column(:source_url).of_type(:string).with_options(limit: 1024, null: true) }
    it { is_expected.not_to validate_presence_of(:source_url) }
  end

  # Project::STATUSES (R2) -- single source of truth referenced by both the status column's
  # own inclusion validation (see "schema and validations" above) and the /projects
  # status-filter UI (spec/requests/projects_spec.rb).
  describe 'STATUSES' do
    it 'is the fixed set of valid status values, in filter-display order' do
      expect(described_class::STATUSES).to eq(%w[Pre-Launch Beta Live])
    end
  end

  # Project.by_status (R2) -- drives the server-rendered status filter directly from the view
  # (spec/requests/projects_spec.rb exercises the full request-level wiring); these specs cover
  # the scope's own filtering behavior in isolation.
  describe '.by_status' do
    it 'returns only the projects matching the given status' do
      live = create(:project, slug: 'live-project', status: 'Live')
      create(:project, slug: 'beta-project', status: 'Beta')

      expect(described_class.by_status('Live')).to contain_exactly(live)
    end

    it 'returns every project when the status is nil' do
      live = create(:project, slug: 'live-project', status: 'Live')
      beta = create(:project, slug: 'beta-project', status: 'Beta')

      expect(described_class.by_status(nil)).to contain_exactly(live, beta)
    end

    it 'returns every project when the status is a blank string' do
      live = create(:project, slug: 'live-project', status: 'Live')
      beta = create(:project, slug: 'beta-project', status: 'Beta')

      expect(described_class.by_status('')).to contain_exactly(live, beta)
    end

    it 'returns no projects (not an error) for an unrecognized status value' do
      create(:project, slug: 'live-project', status: 'Live')

      expect(described_class.by_status('Nonexistent')).to be_empty
    end
  end

  # Project.featured / Project.for_home (1181 R2) -- curated-first, chronological-fallback.
  # Deliberately nested outside the "schema and validations" group above (no
  # `before { create(:project) }` in scope here) so these behavioral tests control every row in
  # the table themselves.
  describe '.featured' do
    it 'returns only the projects flagged featured' do
      featured_project = create(:project, slug: 'featured-project', featured: true)
      create(:project, slug: 'unfeatured-project', featured: false)

      expect(described_class.featured).to contain_exactly(featured_project)
    end
  end

  describe '.for_home' do
    it 'prefers the curated (featured) set over the chronological fallback when some projects are featured' do
      featured_project = create(:project, slug: 'featured-project', featured: true, created_at: 2.days.ago)
      create(:project, slug: 'unfeatured-project', featured: false, created_at: 1.day.ago)

      expect(described_class.for_home.to_a).to eq([featured_project])
    end

    it 'falls back to the most recently created projects, newest first, when none are featured' do
      oldest = create(:project, slug: 'oldest-project', created_at: 3.days.ago)
      middle = create(:project, slug: 'middle-project', created_at: 2.days.ago)
      newest = create(:project, slug: 'newest-project', created_at: 1.day.ago)

      expect(described_class.for_home.to_a).to eq([newest, middle, oldest])
    end

    it 'respects the limit argument, returning only that many projects even when more are available' do
      5.times { |i| create(:project, slug: "project-#{i}", created_at: i.days.ago) }

      expect(described_class.for_home(limit: 2).size).to eq(2)
    end
  end
end
