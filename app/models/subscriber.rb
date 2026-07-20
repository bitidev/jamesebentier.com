# frozen_string_literal: true

# Represents a newsletter subscriber captured via the double opt-in signup flow.
# Lifecycle: pending (created) → confirmed (email verified) → unsubscribed (opted out).
# Re-subscribe from the same email is allowed: unsubscribing clears `unsubscribed_at`
# and starts a fresh pending confirm cycle.
#
# IP address is never stored in plain text; `ip_hash` is a one-way SHA-256 digest of
# the remote IP combined with a secret pepper (see `ip_hash_for`).
class Subscriber < ApplicationRecord
  VALID_EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/i

  declare_schema id: :uuid, default: 'gen_random_uuid()' do
    string :email, limit: 255, null: false,
                   validates: {
                     presence: true,
                     format: { with: VALID_EMAIL_REGEX, message: "is not a valid email address" },
                     uniqueness: { case_sensitive: false }
                   },
                   index: { unique: true }

    string :confirmation_token, limit: 255, null: true, index: { unique: true }

    datetime :confirmed_at,    null: true
    datetime :unsubscribed_at, null: true
    datetime :consent_at,      null: true

    string :consent_source, limit: 50,  null: true
    string :ip_hash,        limit: 64,  null: true
  end

  before_validation :normalize_email

  def confirmed?    = confirmed_at.present?
  def unsubscribed? = unsubscribed_at.present?
  def pending?      = !confirmed? || unsubscribed?

  def generate_confirmation_token!
    update!(confirmation_token: SecureRandom.urlsafe_base64(32))
  end

  # Build the one-way IP hash. Uses `NEWSLETTER_IP_PEPPER` env var when available;
  # falls back to the first 32 chars of `secret_key_base` so there is always a secret.
  def self.ip_hash_for(remote_ip)
    return nil if remote_ip.blank?

    pepper = ENV.fetch("NEWSLETTER_IP_PEPPER") { Rails.application.secret_key_base.first(32) }
    Digest::SHA256.hexdigest("#{pepper}:#{remote_ip}")
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
