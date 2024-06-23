# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    slug { "the-blog-is-back" }
    title { "The Blog is Back" }
    description { "Something about the blogs return" }
    keywords { "blog, return, back, new, fresh" }
    image { "logo192.png" }
    published_at { Time.now }
    file_path { 'blog/the-blog-is-back.md' }
  end
end
