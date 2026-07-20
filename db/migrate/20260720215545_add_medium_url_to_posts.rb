class AddMediumUrlToPosts < ActiveRecord::Migration[4.2]
  def self.up
    add_column :posts, :medium_url, :string, limit: 1024, null: true
  end

  def self.down
    remove_column :posts, :medium_url
  end
end
