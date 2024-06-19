# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base # rubocop:disable Style/Documentation
  primary_abstract_class

  class << self
    # If you want to exclude a model from the sitemap, you can override this method to return true
    def noindex = false
  end
end
