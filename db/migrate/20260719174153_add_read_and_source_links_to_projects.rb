class AddReadAndSourceLinksToProjects < ActiveRecord::Migration[4.2]
  def self.up
    add_column :projects, :read_url, :string, limit: 1024, null: true

    add_column :projects, :source_url, :string, limit: 1024, null: true
  end

  def self.down
    remove_column :projects, :source_url

    remove_column :projects, :read_url
  end
end
