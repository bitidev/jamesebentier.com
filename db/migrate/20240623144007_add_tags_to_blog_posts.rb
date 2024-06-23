class AddTagsToBlogPosts < ActiveRecord::Migration[4.2]
  def self.up
    add_column :posts, :tags, :json, null: false, default: []
  end

  def self.down
    remove_column :posts, :tags
  end
end
