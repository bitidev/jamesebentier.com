class AddFeaturedToProjectsAndPosts < ActiveRecord::Migration[4.2]
  def self.up
    add_column :projects, :featured, :boolean, null: false, default: false

    add_column :posts, :featured, :boolean, null: false, default: false
  end

  def self.down
    remove_column :posts, :featured

    remove_column :projects, :featured
  end
end
