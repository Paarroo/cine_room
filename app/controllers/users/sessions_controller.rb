class Users::SessionsController < Devise::SessionsController
  # GET /users/sign_in
  def new
    super
  end

  # POST /users/sign_in
  def create
    super
  end

  # DELETE /users/sign_out
  def destroy
    super
  end

  protected

  # Override Devise's default redirect after sign in
  def after_sign_in_path_for(resource)
    if resource.respond_to?(:admin?) && resource.admin?
      admin_root_path  # Redirect admins to ActiveAdmin
    elsif resource.creator?
      users_dashboard_path(resource)
    else
      users_dashboard_path(resource)
    end
  end

  # Override Devise's default redirect after sign out
  def after_sign_out_path_for(resource_or_scope)
    public_site_path
  end

  private

  # Method called by ApplicationController
  # Even if not used here, it must exist to avoid error
  def configure_permitted_parameters
    # Optional: customize permitted parameters for sessions
    # Generally not needed for sessions, but required by inheritance
  end
end
