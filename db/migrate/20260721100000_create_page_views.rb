# frozen_string_literal: true

class CreatePageViews < ActiveRecord::Migration[8.1] # rubocop:disable Style/Documentation
  def change # rubocop:disable Metrics/MethodLength
    create_table :page_views, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :path, limit: 2048, null: false
      t.string :referrer, limit: 500
      t.string :utm_source, limit: 255
      t.string :utm_medium, limit: 255
      t.string :utm_campaign, limit: 255
      t.datetime :recorded_at, null: false
      t.string :visitor_type, limit: 10, null: false, default: "human"
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.integer :lock_version, default: 1, null: false
    end

    add_index :page_views, :recorded_at
    add_index :page_views, %i[path recorded_at]
  end
end
