# frozen_string_literal: true

# Single source of truth for the site's build-in-public changelog (#1191): loads
# db/changelog.yml (an ordered, newest-first list of releases) and exposes it both to the
# `/changelog` page (Changelog.releases) and to the footer's site version
# (Changelog.current_version) -- one parse, two call sites, so the two can never drift apart.
#
# A plain PORO, not an ActiveRecord model: a changelog is static, owner-edited, in-repo
# content (like the blog markdown files in db/seeds.rb), not row data -- no table, no
# migration.
class Changelog
  SOURCE_FILE = Rails.root.join("db/changelog.yml")

  # One release entry. `date` is a Date, `changes` an array of strings (inline markdown
  # allowed -- render through BlogHelper#render_markdown at the view layer, same pipeline
  # as everywhere else on the site).
  Release = Struct.new(:version, :date, :title, :changes, keyword_init: true)

  class << self
    # Ordered releases, newest first. Order is *trusted from the file* (db/changelog.yml
    # is hand-curated, newest entry on top) rather than re-sorted here -- there's no
    # re-sort to guarantee semver ordering, so a misordered file renders misordered
    # rather than silently "fixing" itself. Memoized; call .reset! (tests only) to
    # force a re-read.
    def releases
      @releases ||= load_releases
    end

    # The newest release (the top of the file), or nil if the file is missing/malformed
    # or has no entries.
    def current
      releases.first
    end

    # The newest release's version string, or nil in the same degraded cases as .current
    # -- the footer omits the version entirely rather than rendering a bare "v".
    def current_version
      current&.version
    end

    # Test-only escape hatch so specs can reset memoization between examples that swap
    # out SOURCE_FILE's contents or exercise the malformed/missing-file path.
    def reset!
      @releases = nil
    end

    private

    def load_releases
      raw = YAML.safe_load_file(SOURCE_FILE, permitted_classes: [Date])
      raise TypeError, "expected an Array, got #{raw.class}" unless raw.is_a?(Array)

      raw.map { |entry| Release.new(**entry.symbolize_keys) }
    rescue StandardError => e
      # A missing or malformed changelog must never 500 the whole site -- the footer
      # renders Changelog.current_version on every Home request. Degrade to an empty
      # list (current/current_version become nil) and log loudly instead.
      Rails.logger.warn("Changelog failed to load #{SOURCE_FILE}: #{e.class}: #{e.message}")
      []
    end
  end
end
