class Admin::ApplicationController < ApplicationController
  before_action :authenticate_admin_user!

  protected

  def authenticate_admin_user!
    authenticate_user!
    access_denied unless current_user&.admin?
  end

  def access_denied(exception = nil)
    redirect_to root_path, alert: "Tu n'as pas les droits nécessaires pour accéder à cet espace !"
  end
end
