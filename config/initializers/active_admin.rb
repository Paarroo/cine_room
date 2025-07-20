ActiveAdmin.setup do |config|
  config.site_title = "CinéRoom Admin"
  config.site_title_link = "/"

  config.logout_link_path = "/admin/logout"
  config.logout_link_method = :delete

  config.authentication_method = :authenticate_admin_user!
  config.current_user_method = :current_admin_user
  config.logout_link_path = :destroy_user_session_path
  config.logout_link_method = :delete

  config.batch_actions = true
  config.filter_attributes = [ :encrypted_password, :password, :password_confirmation ]

  config.default_namespace = :admin
  config.default_per_page = 30
  config.filters = true
end
