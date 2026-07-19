# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    slug { "the-blog-is-back" }
    title { "The Blog is Back" }
    description { "Something about the blogs return" }
    keywords { "blog, return, back, new, fresh" }
    # A full URL, not a bare filename: Post renders through components/_card (welcome/index.html.erb's
    # Latest Writing section, 1181 R4), which calls Rails' own image_tag -- a bare filename would
    # resolve through the asset pipeline and raise Sprockets::Rails::Helper::AssetNotFound in test,
    # unlike the plain `<img src=...>` blog/index.html.erb uses. Mirrors spec/factories/project.rb's
    # own full-URL convention, which the same components/_card partial already renders safely.
    image { "https://example.com/logo192.png" }
    published_at { Time.current }
    file_path { 'blog/the-blog-is-back.md' }
    # kind mirrors spec/factories/project.rb's own `status { "Beta" }` convention of stating
    # the schema default explicitly rather than relying on it silently. excerpt is
    # presence-validated with no schema default that satisfies it (P1.4/#1183 D4), so every
    # create(:post) call site needs a real value.
    kind { "deep_dive" }
    excerpt { "A short teaser for the blog's return." }
  end
end
