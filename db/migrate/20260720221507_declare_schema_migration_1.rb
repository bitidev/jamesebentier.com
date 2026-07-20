class DeclareSchemaMigration1 < ActiveRecord::Migration[4.2]
  def self.up
    create_table :subscribers, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string   :email, limit: 255, null: false
      t.string   :confirmation_token, limit: 255, null: true
      t.datetime :confirmed_at, null: true
      t.datetime :unsubscribed_at, null: true
      t.datetime :consent_at, null: true
      t.string   :consent_source, limit: 50, null: true
      t.string   :ip_hash, limit: 64, null: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.integer  :lock_version, limit: 4, null: false, default: 1
    end


    add_index :subscribers, [:email], name: :index_subscribers_on_email, unique: true

    add_index :subscribers, [:confirmation_token], name: :index_subscribers_on_confirmation_token, unique: true
  end

  def self.down
    remove_index :subscribers, name: :index_subscribers_on_confirmation_token

    remove_index :subscribers, name: :index_subscribers_on_email

    drop_table :subscribers
  end
end
