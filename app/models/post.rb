# frozen_string_literal: true

# This is the Post model that represents the blog posts that James Ebentier writes.
class Post < ApplicationRecord
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
  end

  before_validation -> { self.slug = slug.downcase if slug.present? }

  scope :published, -> { where(published_at: ..Time.zone.now) }
  scope :featured, -> { where(featured: true) }

  # Curated-first, chronological-fallback, always within `published`: prefer
  # explicitly featured posts if any exist, otherwise fall back to the `limit`
  # most recently published posts overall. See docs/specs/1181-home-hero-redesign.md (R2).
  def self.for_home(limit: 3)
    published.featured.any? ? published.featured.order(published_at: :desc).limit(limit) : published.order(published_at: :desc).limit(limit)
  end

  def content
    @content ||= begin
      file_content = Rails.public_path.join('blog', file_path).read
      file_content.split("---\n", 3).last.chomp
    end
  end
end
