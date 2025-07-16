class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :bio ])
  end

  def ensure_admin!
    redirect_to root_path, alert: 'Access denied.' unless current_user&.admin?
  end

  def ensure_creator_or_admin!
    unless current_user&.admin? || current_user&.creator
      redirect_to root_path, alert: 'Creator access required.'
    end
  end
  def authenticate_admin_user!
    redirect_to new_user_session_path unless user_signed_in? && current_user.admin?
  end
end
