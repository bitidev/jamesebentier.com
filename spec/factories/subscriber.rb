# frozen_string_literal: true

FactoryBot.define do
  factory :subscriber do
    sequence(:email) { |n| "subscriber#{n}@example.com" }
    consent_at { Time.current }
    consent_source { "footer" }

    trait :pending do
      confirmation_token { SecureRandom.urlsafe_base64(32) }
    end

    trait :confirmed do
      confirmation_token { SecureRandom.urlsafe_base64(32) }
      confirmed_at { Time.current }
    end

    trait :unsubscribed do
      confirmation_token { SecureRandom.urlsafe_base64(32) }
      confirmed_at { 1.day.ago }
      unsubscribed_at { Time.current }
    end
  end
end
