# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    slug { "not-my-real-email" }
    title { "Not My Real Email" }
    status { "Beta" }
    url { "https://notmyrealemail.com" }
    image { "https://notmyrealemail.com/logo192.png" }
    description { "Something about emails" }
  end
end
