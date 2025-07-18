class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?

   include Pundit::Authorization

  def after_sign_in_path_for(resource)
     if resource.role == 'admin'
       admin_root_path
     else
       root_path
     end
   end

   def after_sign_out_path_for(resource_or_scope)
     new_user_session_path
   end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :bio ])
  end

  def authenticate_user!
      redirect_to new_user_session_path unless user_signed_in?
    end

    def current_user
      @current_user ||= super
    end

  def ensure_admin!
    redirect_to root_path, alert: 'Accès refusé !' unless current_user&.admin?
  end

  def ensure_creator_or_admin!
    unless current_user&.admin? || current_user&.creator
      redirect_to root_path, alert: 'Les droits de Créateur te sont requis pour y accéder !'
    end
  end
  def authenticate_admin_user!
      authenticate_user!
      unless current_user&.admin?
        redirect_to root_path, alert: "Tu n'as pas les permissions pour accéder à cet espace !"
      end
  end

    def current_admin_user
        current_user if current_user&.admin?
    end
end
