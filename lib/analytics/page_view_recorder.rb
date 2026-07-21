# frozen_string_literal: true

module Analytics
  # Shared ingest path for full-page `after_action` recording and the Turbo beacon POST.
  class PageViewRecorder
    SKIP_EXACT_PATHS = %w[/up /search-index.json /analytics/stats.json].freeze
    SKIP_PREFIXES = %w[/assets /packs /rails/active_storage /analytics/page_views /newsletter].freeze

    class << self
      def record_from_request!(request)
        return if skip_request?(request)

        create!(
          path: request.path,
          referrer: extract_referrer(request.referer),
          utm_source: request.params[:utm_source].presence,
          utm_medium: request.params[:utm_medium].presence,
          utm_campaign: request.params[:utm_campaign].presence,
          user_agent: request.user_agent
        )
      end

      def record_beacon!(path:, referrer:, user_agent:)
        normalized_path = path.to_s
        return if normalized_path.blank?
        return if skip_path?(normalized_path)

        create!(
          path: normalized_path,
          referrer: extract_referrer(referrer),
          user_agent: user_agent
        )
      end

      private

      def create!(attributes)
        PageView.create!(
          path: attributes.fetch(:path).to_s.truncate(2048),
          referrer: attributes[:referrer]&.truncate(500),
          utm_source: attributes[:utm_source]&.truncate(255),
          utm_medium: attributes[:utm_medium]&.truncate(255),
          utm_campaign: attributes[:utm_campaign]&.truncate(255),
          recorded_at: Time.current,
          visitor_type: BotDetector.visitor_type(attributes[:user_agent])
        )
      end

      def skip_request?(request)
        return true unless request.get?
        return true if request.xhr?
        return true if request.headers["Turbo-Frame"].present?
        return true if turbo_visit?(request)

        skip_path?(request.path)
      end

      def turbo_visit?(request)
        request.headers["Turbo-Visit"].present?
      end

      def skip_path?(path)
        return true if SKIP_EXACT_PATHS.include?(path)
        return true if SKIP_PREFIXES.any? { |prefix| path.start_with?(prefix) }

        false
      end

      def extract_referrer(referrer)
        return nil if referrer.blank?

        uri = URI.parse(referrer)
        return referrer.truncate(500) unless uri.host

        "#{uri.host}#{uri.path}".truncate(500)
      rescue URI::InvalidURIError
        referrer.truncate(500)
      end
    end
  end
end
