# frozen_string_literal: true

require_relative "boot"

# There are warnings coming out of the mail gem that are not useful, and
# will be fixed in the next version releases, so we can ignore them.
require "warning"
Warning.ignore(/.*statement not reached.*/, /.*mail-2.8.1.*/)
Warning.ignore(/.*assigned but unused variable.*/, /.*mail-2.8.1.*/)

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module JamesEbentier
  class Application < Rails::Application # rubocop:disable Style/Documentation
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Don't generate system test files.
    config.generators do |g|
      g.test_framework   :rspec, fixtures: true, views: false
      g.integration_tool :rspec, fixtures: true, views: true

      # Don't generate system test files.
      g.system_tests = nil
    end
  end
end
