# frozen_string_literal: true

require "rails_helper"

RSpec.describe PageView do
  describe "schema" do
    it { is_expected.to have_db_column(:id).of_type(:uuid) }
    it { is_expected.to have_db_column(:path).of_type(:string).with_options(limit: 2048, null: false) }
    it { is_expected.to have_db_column(:referrer).of_type(:string).with_options(limit: 500, null: true) }
    it { is_expected.to have_db_column(:recorded_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:visitor_type).of_type(:string).with_options(limit: 10, null: false) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_presence_of(:recorded_at) }
    it { is_expected.to validate_presence_of(:visitor_type) }
    it { is_expected.to validate_inclusion_of(:visitor_type).in_array(PageView::VISITOR_TYPES) }
  end
end
