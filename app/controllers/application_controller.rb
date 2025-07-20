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

   def current_admin_user
     current_user if current_user&.admin?
   end

   def authenticate_admin_user!
     unless current_user&.admin?
       flash[:alert] = "Accès non autorisé. Droits administrateur requis."
       redirect_to root_path
     end
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

   # Set locale (if internationalization is needed)
   def set_locale
     I18n.locale = params[:locale] || I18n.default_locale
   end

   def track_activity
     return unless current_user

     current_user.update_column(:last_seen_at, Time.current) if current_user.respond_to?(:last_seen_at)
   end

   private

   # Handle different types of format requests
   def respond_with_format(object, options = {})
     respond_to do |format|
       format.html { redirect_to options[:redirect_to] || object }
       format.json { render json: object }
       format.turbo_stream { render options[:turbo_stream] } if options[:turbo_stream]
     end
   end

   # Common flash message helper
   def set_flash_message(type, message)
     flash[type] = message
   end

   # Breadcrumb helper for admin pages
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
