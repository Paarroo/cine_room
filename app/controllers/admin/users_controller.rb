class Admin::UsersController < Admin::ApplicationController
  def index
    @users = User.includes(:movies, :participations)
  end

  def show
    @user = User.find(params[:id])
  end

  def update_role
    @user = User.find(params[:id])
    @user.update(role: params[:role])
    redirect_to admin_user_path(@user)
  end
end
