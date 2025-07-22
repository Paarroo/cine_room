class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  allow_browser versions: :modern

  before_action :authenticate_user!, except: [
    # Static pages
    :home, :about, :contact, :legal, :privacy, :terms,
    # Public movie browsing
    :index, :show, :search, :by_genre, :featured,
    # Public event browsing
    :filter, :calendar, :upcoming, :past, :availability,
    # Public creator profiles
    :portfolio, :events,
    # Public reviews reading
    :recent, :top_rated
  ]

  before_action :configure_permitted_parameters, if: :devise_controller?

  

  def set_admin_layout
      if request.path.starts_with?('/admin')
        self.class.layout 'active_admin'
      end
    end

  # Admin-specific methods
  def authenticate_admin_user!
    unless current_user&.admin?
      flash[:alert] = "Accès non autorisé. Droits administrateur requis."
      redirect_to root_path
    end
  end

  def current_admin_user
    current_user if current_user&.admin?
  end

  def admin_logout
    if current_user&.admin?
      sign_out(current_user)
      flash[:notice] = "Déconnexion administrative réussie."
      redirect_to new_user_session_path
    else
      redirect_to root_path, alert: "Action non autorisée."
    end
  end

  def not_found
    render 'errors/404', status: :not_found, layout: 'application'
  end

  # Global error handler
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::RoutingError, with: :not_found

  protected

  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_root_path
    elsif resource.creator?
      users_dashboard_path(resource)
    else
      users_dashboard_path(resource)
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  def ensure_admin!
    unless current_user&.admin?
      flash[:alert] = "Accès administrateur requis."
      redirect_to root_path
    end
  end

  def ensure_owner_or_admin!(resource)
    unless resource.user == current_user || current_user&.admin?
      flash[:alert] = "Vous ne pouvez accéder qu'à vos propres ressources."
      redirect_to root_path
    end
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :bio ])
  end

  def set_flash_message(type, message)
    flash[type] = message
  end

  def add_breadcrumb(name, path = nil)
    @breadcrumbs ||= []
    @breadcrumbs << { name: name, path: path }
  end

  def set_page_title(title)
    @page_title = title
  end

  def set_meta_tags(tags = {})
    @meta_tags = tags
  end
end
