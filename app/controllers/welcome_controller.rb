# frozen_string_literal: true

# The WelcomeController is used to host the landing pages and supplimentary content for the application.
class WelcomeController < ApplicationController
  STATS_WINDOW = "7d"

  # Real first-party figures for the Home "stats" block (#1226 PR review fix) -- reuses
  # Analytics::StatsQuery so the Home total always agrees with what `:stats views --last 7d`
  # reports (both read PageView's "views" metric with no visitor_type filter).
  def index
    @views_stats = Analytics::StatsQuery.fetch(metric: "views", window: STATS_WINDOW)
    @daily_view_counts = Analytics::StatsQuery.daily_view_counts(window: STATS_WINDOW)
  end

  def about; end
  def projects; end
  def resume; end
  def privacy; end
end
