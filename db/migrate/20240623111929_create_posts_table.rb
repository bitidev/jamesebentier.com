class CreatePostsTable < ActiveRecord::Migration[4.2]
  def self.up
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :posts, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string   :slug, limit: 255, null: false
      t.string   :title, limit: 1024, null: false
      t.string   :description, limit: 1024, null: false
      t.string   :keywords, limit: 1024, null: false
      t.string   :image, limit: 1024, null: false, default: ""
      t.string   :file_path, limit: 1024, null: false
      t.datetime :published_at, null: false
      t.datetime :created_at, null: true
      t.datetime :updated_at, null: true
      t.integer  :lock_version, limit: 4, null: false, default: 1
    end


    add_index :posts, [:slug], name: :index_posts_on_slug, unique: true
  end

  def self.down
    remove_index :posts, name: :index_posts_on_slug

    drop_table :posts
  end
end
