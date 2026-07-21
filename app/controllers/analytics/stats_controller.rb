# frozen_string_literal: true

module Analytics
  # GET /analytics/stats.json — public aggregate stats for the COMMAND-mode `:stats` command.
  class StatsController < ApplicationController
    def show
      parsed = StatsQuery.parse_metric_and_args(params[:q].to_s)
      return render json: { error: "invalid stats query" }, status: :bad_request unless parsed

      render json: StatsQuery.fetch(**parsed)
    end
  end
end
