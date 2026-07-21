# frozen_string_literal: true

module Analytics
  # POST /analytics/page_views — Turbo Drive beacon for client-side navigations.
  class PageViewsController < ApplicationController
    def create
      Analytics::PageViewRecorder.record_beacon!(
        path: page_view_params[:path],
        referrer: page_view_params[:referrer],
        user_agent: request.user_agent
      )
      head :no_content
    rescue StandardError => e
      Rails.logger.warn("page view beacon failed: #{e.class}: #{e.message}")
      head :no_content
    end

    private

    def page_view_params
      params.permit(:path, :referrer)
    end
  end
end
