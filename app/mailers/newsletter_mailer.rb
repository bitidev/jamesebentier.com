# frozen_string_literal: true

# Sends transactional emails for the newsletter double opt-in flow.
# In v1, delivery is log-only (no external ESP). See docs/ops/newsletter-mail.md.
class NewsletterMailer < ApplicationMailer
  default from: "james@jamesebentier.com"

  # Confirmation email sent after signup. Contains the double-opt-in confirm URL.
  def confirmation(subscriber)
    @subscriber   = subscriber
    @confirm_url  = newsletter_confirm_url(token: subscriber.confirmation_token)
    @unsubscribe_url = newsletter_unsubscribe_url(token: subscriber.confirmation_token)

    mail(
      to: subscriber.email,
      subject: "Confirm your subscription to James Ebentier's newsletter" # rubocop:disable Rails/I18nLocaleTexts
    )
  end
end
