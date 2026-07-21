# frozen_string_literal: true

# Records a first-party PageView on every HTML full-page response (#1188). Failures are
# logged and never break the visitor's request.
module PageViewTracking
  extend ActiveSupport::Concern

  included do
    after_action :record_page_view
  end

  private

  def record_page_view
    Analytics::PageViewRecorder.record_from_request!(request)
  rescue StandardError => e
    Rails.logger.warn("page view recording failed: #{e.class}: #{e.message}")
  end
end
