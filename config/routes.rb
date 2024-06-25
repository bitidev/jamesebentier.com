# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "blog"           => "blog#index",       as: :posts
  get "blog/:slug"     => "blog#show",        as: :post
  get "projects"       => "projects#index",   as: :projects
  get "projects/:slug" => "projects#show",    as: :project
  get "resume"         => "welcome#resume",   as: :resume

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "welcome#index"
end
