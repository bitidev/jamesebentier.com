class CreateProjectsTable < ActiveRecord::Migration[4.2]
  def self.up
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :projects, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.string   :slug, limit: 255, null: false
      t.string   :title, limit: 1024, null: false
      t.string   :status, limit: 255, null: false, default: "Beta"
      t.string   :url, limit: 1024, null: false
      t.string   :image, limit: 1024, null: false
      t.text     :description, limit: nil, null: false
      t.datetime :created_at, null: true
      t.datetime :updated_at, null: true
      t.integer  :lock_version, limit: 4, null: false, default: 1
    end


    add_index :projects, [:slug], name: :index_projects_on_slug, unique: true
  end

  def self.down
    remove_index :projects, name: :index_projects_on_slug

    drop_table :projects
  end
end
