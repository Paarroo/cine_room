class ApplicationController < ActionController::Base
  before_action :authenticate_user!, except: [ :home, :about, :contact ]
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
end
