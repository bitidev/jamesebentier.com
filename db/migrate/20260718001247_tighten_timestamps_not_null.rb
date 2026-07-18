class TightenTimestampsNotNull < ActiveRecord::Migration[4.2]
  def self.up
    change_column :projects, :created_at, :datetime, null: false

    change_column :projects, :updated_at, :datetime, null: false

    change_column :posts, :created_at, :datetime, null: false

    change_column :posts, :updated_at, :datetime, null: false
  end

  def self.down
    change_column :posts, :updated_at, :datetime, null: true

    change_column :posts, :created_at, :datetime, null: true

    change_column :projects, :updated_at, :datetime, null: true

    change_column :projects, :created_at, :datetime, null: true
  end
end
