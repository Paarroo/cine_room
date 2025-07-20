# config/initializers/active_admin.rb
# Minimal configuration for ActiveAdmin 3.3.0 + Rails 8 compatibility

ActiveAdmin.setup do |config|
  # Basic site configuration
  config.site_title = "CinéRoom Admin"
  config.site_title_link = "/"
  config.before_action :set_admin_layout
  # Authentication - using your existing Devise setup
  config.authentication_method = :authenticate_admin_user!
  config.current_user_method = :current_admin_user

  # Logout configuration
  config.logout_link_path = "/admin/logout"
  config.logout_link_method = :delete

  # Essential features
  config.batch_actions = true
  config.filter_attributes = [ :encrypted_password, :password, :password_confirmation ]

  # Pagination
  config.default_per_page = 30
  config.max_per_page = 100

  # Namespace
  config.default_namespace = :admin
  config.filters = true

  # Download formats
  config.download_links = [ :csv, :xml, :json ]

  # Footer
  config.footer = "CinéRoom Admin Panel - #{Date.current.year}"

  # CSV options
  config.csv_options = { col_sep: ';', encoding: 'UTF-8' }
end
