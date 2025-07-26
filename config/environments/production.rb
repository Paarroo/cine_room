require "active_support/core_ext/integer/time"

Rails.application.configure do
  # No credential
  config.secret_key_base = ENV['SECRET_KEY_BASE']

   # Assets Heroku
   config.assets.compile = true
   config.assets.digest = true
   config.serve_static_assets = true
   config.action_controller.raise_on_missing_callback_actions = false
   # Desable redentials
   config.require_master_key = false
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  # Enable serving of static files from the `/public` folder
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present? || ENV['RENDER'].present?

  # Compress CSS using a preprocessor
  config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Cache assets for far-future expiry since they are all digest stamped
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :cloudinary

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false


  config.cache_store = :solid_cache_store

  config.solid_cache.store_options = {
    max_age: 60.days.to_i,
    namespace: Rails.env,
    size_estimate_samples: 1000
  }


  # Temporary fix: use inline delivery for emails instead of SolidQueue
  config.active_job.queue_adapter = :inline
  # config.active_job.queue_adapter = :solid_queue
  # config.solid_queue.connects_to = { database: { writing: :queue } }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]


  # config/environments/production.rb
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: 'cineroom-95309b4cb0ca.herokuapp.com/', protocol: 'https' }

    # config.action_mailer.delivery_method = :smtp
    # config.action_mailer.smtp_settings = {
    #   address:              "in-v3.mailjet.com",
    #   port:                 587,
    #   domain:               "cineroom.com",
    #   user_name:            ENV["SMTP_USERNAME"],
    #   password:             ENV["SMTP_PASSWORD"],
    #   authentication:       "plain",
    #   enable_starttls_auto: true
    # }


    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: "smtp.gmail.com",
      port: 587,
      domain: "cineroom-95309b4cb0ca.herokuapp.com",
      authentication: "login",
      enable_starttls_auto: true,
      user_name: ENV["GMAIL_USERNAME"],
      password: ENV["GMAIL_PASSWORD"]
    }
end
