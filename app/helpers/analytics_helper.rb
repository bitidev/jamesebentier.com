# frozen_string_literal: true

# View helper for rendering first-party analytics figures (#1226 PR review fix: the Home
# "stats" block is wired to real Analytics::StatsQuery data, not a hardcoded sample).
module AnalyticsHelper
  SPARKLINE_GLYPHS = %w[▁ ▂ ▃ ▄ ▅ ▆ ▇ █].freeze

  # Maps a daily view-count series (e.g. Analytics::StatsQuery.daily_view_counts) to a
  # sparkline string of block glyphs, one per day, scaled relative to the series max. An
  # all-zero series (brand-new DB, no page views yet) renders as a flat line of the lowest
  # glyph rather than raising or being hidden.
  def sparkline(counts)
    return "" if counts.empty?

    max = counts.max
    counts.map { |count| SPARKLINE_GLYPHS[sparkline_level(count, max)] }.join
  end

  private

  def sparkline_level(count, max)
    return 0 if max.zero?

    ((count.to_f / max) * (SPARKLINE_GLYPHS.size - 1)).round
  end
end
