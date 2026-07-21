# frozen_string_literal: true

FactoryBot.define do
  factory :page_view do
    path { "/writing/example-post" }
    referrer { nil }
    recorded_at { Time.current }
    visitor_type { "human" }

    trait :bot do
      visitor_type { "bot" }
    end
  end
end
