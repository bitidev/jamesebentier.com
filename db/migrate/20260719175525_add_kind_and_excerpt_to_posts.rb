class AddKindAndExcerptToPosts < ActiveRecord::Migration[4.2]
  def self.up
    add_column :posts, :kind, :string, limit: 20, null: false, default: "deep_dive"

    add_column :posts, :excerpt, :string, limit: 280, null: false, default: ""

    # excerpt has no DB-level default that satisfies its presence validation (D4) -- without
    # this, the next db:seed run's front-matter re-`update!` on any pre-existing post would
    # raise ActiveRecord::RecordInvalid. Backfilling here (once) keeps every existing row valid.
    Post.backfill_excerpt_from_description!
  end

  def self.down
    remove_column :posts, :excerpt

    remove_column :posts, :kind
  end
end
