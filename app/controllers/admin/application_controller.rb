class Admin::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_access

  private

  def ensure_admin_access
    unless current_user&.admin?
      redirect_to root_path, alert: 'Accès administrateur requis'
    end
  end

  def authenticate_admin_user!
    authenticate_user!
    ensure_admin_access
  end

  def current_admin_user
    current_user if current_user&.admin?
  end
end
