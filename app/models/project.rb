# frozen_string_literal: true

# This is the Project model that represents the projects that James Ebentier is working on.
class Project < ApplicationRecord
  # Single source of truth for valid status values -- shared by the inclusion validation
  # below and the /projects status-filter UI (see docs/specs/1182-projects-page-redesign.md R2).
  STATUSES = %w[Pre-Launch Beta Live].freeze

  # Terminal-redesign status-dot color (#1226 design doc's Home/Projects sections) --
  # DaisyUI text-* roles only (no hex), same fallback discipline as
  # components/pill's status_badge_roles: an unrecognized status renders muted rather
  # than raising.
  STATUS_TEXT_CLASSES = {
    "Pre-Launch" => "text-warning",
    "Beta" => "text-info",
    "Live" => "text-success"
  }.freeze

  declare_schema id: :uuid, default: 'gen_random_uuid()' do
    string :slug,   limit: 255,  null: false, validates: { presence: true, uniqueness: true }, index: { unique: true }
    string :title,  limit: 1024, null: false, validates: { presence: true }
    string :status, limit: 255, null: false,  validates: { presence: true, inclusion: { in: STATUSES } },
                    default: 'Beta'
    string :url,    limit: 1024, null: false, validates: { presence: true }
    string :image,  limit: 1024, null: false, validates: { presence: true }
    text   :description, null: false, validates: { presence: true }
    boolean :featured, null: false, default: false
    # Triple-link pattern (read -> demo -> source): `url` above is the required "demo" leg;
    # these two are the optional "read" (write-up/article) and "source" (repo) legs. Both
    # nullable, no presence validation -- see docs/specs/1182-projects-page-redesign.md R1.
    string :read_url,   limit: 1024, null: true
    string :source_url, limit: 1024, null: true
  end

  scope :featured, -> { where(featured: true) }
  # Server-rendered status filter (R4): blank status returns everything; an unrecognized
  # status simply yields zero rows via AR's own where(), never a 500.
  scope :by_status, ->(status) { status.present? ? where(status: status) : all }

  # Curated-first, chronological-fallback: prefer explicitly featured projects: if
  # any exist, return up to `limit` of them (newest first); otherwise fall back to
  # the `limit` most recently created projects overall. See docs/specs/1181-home-hero-redesign.md (R2).
  def self.for_home(limit: 3)
    featured.any? ? featured.order(created_at: :desc).limit(limit) : order(created_at: :desc).limit(limit)
  end

  def status_color_class
    STATUS_TEXT_CLASSES.fetch(status, "text-base-content/50")
  end

  def content
    @content ||= if (file_path = Rails.public_path.join('projects', "#{slug}.md")).exist?
                   file_path.read
                 else
                   '_Project Details Coming Soon_'
                 end
  end
end
