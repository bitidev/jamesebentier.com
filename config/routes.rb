# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "writing"        => "writing#index",    as: :posts
  get "writing/:slug"  => "writing#show",     as: :post
  get "projects"       => "projects#index",   as: :projects
  get "projects/:slug" => "projects#show",    as: :project
  get "about"          => "welcome#about",    as: :about
  get "resume"         => "welcome#resume",   as: :resume
  get "privacy"        => "welcome#privacy",  as: :privacy
  get "impressum"      => "welcome#impressum", as: :impressum

  # Newsletter double opt-in
  post "newsletter"            => "newsletters#create",      as: :newsletters
  get  "newsletter/confirm"    => "newsletters#confirm",     as: :newsletter_confirm
  get  "newsletter/unsubscribe" => "newsletters#unsubscribe", as: :newsletter_unsubscribe

  # SEARCH mode's content index (#1187 R9) -- a JSON array of Post/Project items,
  # fetched lazily and cached client-side (app/javascript/keyboard_nav/search_index.js).
  get "search-index.json" => "search_index#index", as: :search_index

  # First-party analytics (#1188) — Turbo beacon + COMMAND-mode stats JSON.
  post "analytics/page_views" => "analytics/page_views#create", as: :analytics_page_views
  get  "analytics/stats.json" => "analytics/stats#show", as: :analytics_stats

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "welcome#index"
end
