# frozen_string_literal: true

class ApplicationController < ActionController::Base # rubocop:disable Style/Documentation
  class << self
    # If you want to exclude a controller from the sitemap, you can override this method to return true
    def noindex = false
  end
end
