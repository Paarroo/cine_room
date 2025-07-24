require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CineRoom
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0
    if Rails.env.production?
          config.secret_key_base = ENV['SECRET_KEY_BASE']
    end
    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.assets.precompile += %w( active_admin.css active_admin.js )
    config.action_controller.raise_on_missing_callback_actions = false
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.assets.paths << Rails.root.join("app", "assets", "stylesheets")
    config.assets.paths << Rails.root.join("app", "assets", "javascripts")
    config.assets.paths << Rails.root.join("app/assets/images")

    config.assets.css_compressor = nil

    config.i18n.available_locales = [ :fr, :en ]
    config.i18n.default_locale = :fr
    # config.middleware.use MaintenanceMode
  end
end
