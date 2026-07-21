# frozen_string_literal: true

module Analytics
  # Aggregate queries backing GET /analytics/stats.json and the COMMAND-mode `:stats` command.
  class StatsQuery
    LAST_WINDOW_PATTERN = /\A--last\s+(\d+)([dh])\z/i

    METRICS = %w[views top_posts referrers].freeze

    class << self
      def parse_last_window(args, default: "7d")
        match = args.match(LAST_WINDOW_PATTERN)
        return default unless match

        "#{match[1]}#{match[2].downcase}"
      end

      def window_start(window)
        amount, unit = window.match(/\A(\d+)([dh])\z/i).captures
        duration = unit == "h" ? amount.to_i.hours : amount.to_i.days
        Time.current - duration
      end

      def metric_from_subcommand(subcommand, remainder)
        case subcommand
        when "views"
          "views"
        when "top"
          remainder == "posts" ? "top_posts" : nil
        when "referrers"
          "referrers"
        end
      end

      def parse_metric_and_args(args)
        tokens = args.to_s.strip.split(/\s+/)
        return nil if tokens.empty?

        metric = metric_from_subcommand(tokens[0], tokens[1])
        return nil unless metric && METRICS.include?(metric)

        remainder = metric == "top_posts" ? tokens.drop(2).join(" ") : tokens.drop(1).join(" ")
        { metric: metric, window: parse_last_window(remainder) }
      end

      def fetch(metric:, window:)
        since = window_start(window)
        scope = PageView.where(recorded_at: since..)

        case metric
        when "views" then views_payload(scope, window, since)
        when "top_posts" then ranked_payload("top_posts", window, since, top_post_rows(scope), :path)
        when "referrers" then ranked_payload("referrers", window, since, referrer_rows(scope), :referrer)
        else raise ArgumentError, "unknown metric: #{metric}"
        end
      end

      private

      def views_payload(scope, window, since) # rubocop:disable Metrics/MethodLength
        counts = scope.group(:visitor_type).count
        total = counts.values.sum
        human = counts.fetch("human", 0)
        bot = counts.fetch("bot", 0)

        {
          metric: "views",
          window: window,
          since: since.iso8601,
          total: total,
          human: human,
          bot: bot,
          lines: ["views (#{window}): #{total} total (#{human} human, #{bot} bot)"],
        }
      end

      def top_post_rows(scope)
        scope.where("path LIKE ?", "/writing/%")
             .group(:path)
             .order(Arel.sql("COUNT(*) DESC"))
             .limit(10)
             .count
      end

      def referrer_rows(scope)
        scope.where.not(referrer: [nil, ""])
             .group(:referrer)
             .order(Arel.sql("COUNT(*) DESC"))
             .limit(10)
             .count
      end

      def ranked_payload(metric, window, since, rows, row_key)
        label = metric.tr("_", " ")
        lines = format_ranked_lines("#{label} (#{window})", rows)

        {
          metric: metric,
          window: window,
          since: since.iso8601,
          rows: rows.map { |value, count| { row_key => value, count: count } },
          lines: lines,
        }
      end

      def format_ranked_lines(header, rows)
        return ["#{header}: (no data)"] if rows.empty?

        ["#{header}:"] + rows.map { |label, count| "  #{count.to_s.rjust(4)}  #{label}" }
      end
    end
  end
end
