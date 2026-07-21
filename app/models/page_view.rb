# frozen_string_literal: true

# First-party, cookieless page-view event stored in Postgres (#1188). No client IDs or
# raw IP — only path, referrer, optional UTM params, timestamp, and a human/bot label.
class PageView < ApplicationRecord
  VISITOR_TYPES = %w[human bot].freeze

  declare_schema id: :uuid, default: 'gen_random_uuid()' do
    string :path, limit: 2048, null: false, validates: { presence: true }
    string :referrer, limit: 500, null: true
    string :utm_source, limit: 255, null: true
    string :utm_medium, limit: 255, null: true
    string :utm_campaign, limit: 255, null: true
    datetime :recorded_at, null: false, index: true, validates: { presence: true }
    string :visitor_type, limit: 10, null: false, default: 'human',
                          validates: { presence: true, inclusion: { in: VISITOR_TYPES } }
  end
end
