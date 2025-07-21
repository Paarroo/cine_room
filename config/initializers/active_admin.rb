ActiveAdmin.setup do |config|
  # Basic site configuration
  config.site_title = "CinéRoom Admin"
  # config.site_title_link = "/"

  config.before_action :set_admin_layout
  config.authentication_method = :authenticate_admin_user!
  config.current_user_method = :current_admin_user

  config.logout_link_path = "/admin/logout"
  config.logout_link_method = :delete

  config.batch_actions = true
  config.filter_attributes = [ :encrypted_password, :password, :password_confirmation ]

  config.default_per_page = 30
  config.max_per_page = 100

  config.default_namespace = :admin
  config.filters = false

  config.download_links = [ :csv, :xml, :json ]

  config.footer = "CinéRoom Admin Panel - #{Date.current.year}"

  config.csv_options = { col_sep: ';', encoding: 'UTF-8' }
end
