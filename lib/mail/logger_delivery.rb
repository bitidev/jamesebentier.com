# frozen_string_literal: true

# Custom Action Mailer delivery method that writes email content to the Rails log
# instead of sending it via SMTP or a real ESP.
#
# Used in both development and production until an email service provider is chosen.
# See docs/ops/newsletter-mail.md for how to swap in a real delivery method.
#
# Registration (config/environments/*.rb):
#   config.action_mailer.delivery_method = :logger
#   config.action_mailer.logger_settings  = { log_level: :info }  # optional
module Mail
  class LoggerDelivery # rubocop:disable Style/Documentation
    attr_accessor :settings

    def initialize(settings)
      @settings = settings
    end

    def deliver!(mail)
      level = settings.fetch(:log_level, :info).to_sym
      Rails.logger.public_send(level, <<~LOG)
        [NewsletterMailer] ── Would send email ──────────────────────────────────
          To:      #{mail.to&.join(', ')}
          From:    #{mail.from&.join(', ')}
          Subject: #{mail.subject}
          ── Body (text/plain) ──────────────────────────────────────────────────
          #{mail.text_part&.decoded || mail.body.decoded}
          ──────────────────────────────────────────────────────────────────────
      LOG
    end
  end
end
