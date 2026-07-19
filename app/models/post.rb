# frozen_string_literal: true

# This is the Post model that represents the blog posts that James Ebentier writes.
class Post < ApplicationRecord
  # Notes vs. Deep Dives content model (docs/specs/1183-writing-redesign-notes-deep-dives.md,
  # design doc §5). `kind` is orthogonal to curation (`featured`/`for_home`, #1181) -- a Note
  # is exactly as eligible for either as a Deep Dive.
  KINDS = %w[note deep_dive].freeze
  KIND_LABELS = { "note" => "Note", "deep_dive" => "Deep Dive" }.freeze

  # Word-count -> minute divisor for #reading_time (D5) -- a common blog-reading-time estimate.
  WORDS_PER_MINUTE = 200

  declare_schema id: :uuid, default: 'gen_random_uuid()' do
    string :slug,        limit: 255,  null: false, validates: { presence: true, uniqueness: { case_sensitive: false } }, index: { unique: true }
    string :title,       limit: 1024, null: false, validates: { presence: true }
    string :description, limit: 1024, null: false, validates: { presence: true }
    string :keywords,    limit: 1024, null: false, validates: { presence: true }
    string :image,       limit: 1024, null: false, default: ""
    string :file_path,   limit: 1024, null: false, validates: { presence: true }

    json   :tags, null: false, default: []

    datetime :published_at, null: false, validates: { presence: true }
    boolean :featured, null: false, default: false

    # kind: DB-level default (`deep_dive`) backfills every pre-existing row on the
    # ADD COLUMN itself -- mirrors `featured`'s own precedent (D3). excerpt: real,
    # presence-validated column -- see Post.backfill_excerpt_from_description! below and
    # the migration that calls it once (D4).
    string :kind,    limit: 20,  null: false, default: 'deep_dive', validates: { presence: true, inclusion: { in: KINDS } }
    string :excerpt, limit: 280, null: false, default: '', validates: { presence: true }
  end

  before_validation -> { self.slug = slug.downcase if slug.present? }

  scope :published, -> { where(published_at: ..Time.zone.now) }
  scope :featured, -> { where(featured: true) }

  # Whitelisted filter (D10): an unrecognized/blank/nil `kind` value safely falls back to
  # `all` (unfiltered) rather than raising or silently returning an empty relation.
  scope :by_kind, ->(kind) { KINDS.include?(kind) ? where(kind: kind) : all }

  # Curated-first, chronological-fallback, always within `published`: prefer
  # explicitly featured posts if any exist, otherwise fall back to the `limit`
  # most recently published posts overall. See docs/specs/1181-home-hero-redesign.md (R2).
  def self.for_home(limit: 3)
    published.featured.any? ? published.featured.order(published_at: :desc).limit(limit) : published.order(published_at: :desc).limit(limit)
  end

  # One-time, idempotent backfill for posts whose `excerpt` is still blank (the schema
  # default): copies (a truncated copy of) `description` in. Safe to re-invoke -- a post
  # with a real excerpt already set is left untouched (D4). update_column deliberately
  # skips validation/callbacks here -- this backfill only ever *fills in* an already-valid
  # row's blank excerpt from its own (already-validated) description, never changes any
  # other attribute, so there is nothing to (re-)validate.
  def self.backfill_excerpt_from_description!
    where(excerpt: '').find_each { |post| post.update_column(:excerpt, post.description.truncate(280)) } # rubocop:disable Rails/SkipsModelValidations
  end

  def kind_label
    KIND_LABELS.fetch(kind, kind)
  end

  def content
    @content ||= begin
      file_content = Rails.public_path.join('blog', file_path).read
      file_content.split("---\n", 3).last.chomp
    end
  end

  # Computed, not stored (D5): Post#content is already an intentionally uncached,
  # always-fresh disk read, so a stored reading_time could silently go stale the instant a
  # markdown body is hand-edited without a matching front-matter/DB touch. Always minimum 1.
  def reading_time
    [(content.split.size / WORDS_PER_MINUTE.to_f).ceil, 1].max
  end
end
