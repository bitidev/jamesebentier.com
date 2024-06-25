# frozen_string_literal: true

# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://jamesebentier.com"
SitemapGenerator::Sitemap.compress     = true

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  # Automatically load all models and add any records that have a show path.
  # If the model has a noindex method that returns true, it will be skipped.
  Rails.application.eager_load!
  ApplicationRecord.descendants.each do |model|
    if model.noindex || !Rails.application.routes.url_helpers.respond_to?(:"#{model.name.underscore.pluralize}_path")
      next
    end

    add send(:"#{model.name.underscore.pluralize}_path"), priority: 0.7, changefreq: "daily"
    model.find_each do |record|
      add send(:"#{model.name.underscore}_path", record.try(:slug) || record), lastmod: record.updated_at
    end
  end

  # Add any contoller index methods that are not already included or have noindex set to true
  ApplicationController.descendants.each do |controller|
    next if controller.noindex || controller.instance_methods.exclude?(:index) || !respond_to?(:"#{controller.name.underscore}_path")

    add send(:"#{controller.name.underscore}_path"), priority: 0.7, changefreq: "daily"
  end
end
