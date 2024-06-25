# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Post do
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
end
