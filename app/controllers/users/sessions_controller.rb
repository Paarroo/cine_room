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
    else
      stored_location_for(resource) || root_path  # Regular users to home
    end
  end

  # Override Devise's default redirect after sign out
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
