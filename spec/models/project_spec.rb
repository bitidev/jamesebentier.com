# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project do
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
  it { is_expected.to validate_inclusion_of(:status).in_array(%w[Beta Live]) }

  # URL
  it { is_expected.to have_db_column(:url).of_type(:string).with_options(limit: 1024, null: false) }
  it { is_expected.to validate_presence_of(:url) }

  # Image
  it { is_expected.to have_db_column(:image).of_type(:string).with_options(limit: 1024, null: false) }
  it { is_expected.to validate_presence_of(:image) }

  # Description
  it { is_expected.to have_db_column(:description).of_type(:text).with_options(limit: nil, null: false) }
  it { is_expected.to validate_presence_of(:description) }
end
