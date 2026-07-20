# frozen_string_literal: true

# Handles the newsletter double opt-in flow:
#   POST /newsletter          — signup (create or re-subscribe)
#   GET  /newsletter/confirm  — confirm via token from email link
#   GET  /newsletter/unsubscribe — unsubscribe via token
class NewslettersController < ApplicationController
  # Safe allowlist for post-signup redirect. Anything not on this list falls back to root.
  SAFE_RETURN_PATHS = %w[/ /writing /projects /about].freeze

  def create
    return redirect_to_return_path(alert: "Please accept the consent checkbox.") unless consent_given?

    subscriber = find_or_build_subscriber
    return redirect_to_return_path(notice: "You're already subscribed — thanks!") if active_subscriber?(subscriber)

    prepare_subscriber(subscriber)

    if subscriber.save
      # Inline deliver — v1 is log-only (Mail::LoggerDelivery); no job runner required.
      NewsletterMailer.confirmation(subscriber).deliver_now
      redirect_to_return_path(notice: "Check your email for a confirmation link!")
    else
      redirect_to_return_path(alert: "Couldn't save your subscription: #{subscriber.errors.full_messages.to_sentence}")
    end
  end

  def confirm
    subscriber = Subscriber.find_by(confirmation_token: params[:token])

    if subscriber.nil?
      redirect_to root_path, alert: "Confirmation link is invalid or has already been used." # rubocop:disable Rails/I18nLocaleTexts
    else
      subscriber.update!(confirmed_at: Time.current)
      render :confirm
    end
  end

  def unsubscribe
    subscriber = Subscriber.find_by(confirmation_token: params[:token])

    if subscriber.nil?
      redirect_to root_path, alert: "Unsubscribe link is invalid." # rubocop:disable Rails/I18nLocaleTexts
    else
      subscriber.update!(unsubscribed_at: Time.current)
      render :unsubscribe
    end
  end

  private

  def subscriber_params
    params.expect(subscriber: %i[email source])
  end

  def consent_given?
    params[:subscriber] && params[:subscriber][:consent] == "1"
  end

  def find_or_build_subscriber
    email = subscriber_params[:email].to_s.downcase.strip
    Subscriber.find_or_initialize_by(email: email)
  end

  def active_subscriber?(subscriber)
    subscriber.persisted? && subscriber.confirmed? && !subscriber.unsubscribed?
  end

  def prepare_subscriber(subscriber)
    source = subscriber_params[:source].presence || "unknown"
    subscriber.assign_attributes(
      consent_at: Time.current,
      consent_source: source,
      confirmed_at: nil,
      unsubscribed_at: nil,
      ip_hash: Subscriber.ip_hash_for(request.remote_ip)
    )
    subscriber.confirmation_token = SecureRandom.urlsafe_base64(32)
  end

  # Redirects to the referrer if it's a safe same-origin path, otherwise root.
  def redirect_to_return_path(flash_opts)
    referer_path = begin
      URI.parse(request.referer || "").path
    rescue URI::InvalidURIError
      "/"
    end

    target = SAFE_RETURN_PATHS.include?(referer_path) ? referer_path : root_path
    redirect_to target, flash_opts
  end
end
