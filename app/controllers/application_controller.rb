# frozen_string_literal: true

class ApplicationController < ActionController::Base # rubocop:disable Style/Documentation
  class << self
    # If you want to exclude a controller from the sitemap, you can override this method to return true
    def noindex = false
  end

  def default_url_options
    if Rails.env.production?
      { host: "jamesebentier.com" }
    else
      {}
    end
  end
end
