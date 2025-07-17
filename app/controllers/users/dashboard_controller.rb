class Users::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show
    @upcoming_participations = @user.participations.joins(:event).where("event_date >= ?", Date.today).order("events.event_date ASC").limit(5)
    @past_participations = @user.participations.joins(:event).where("event_date < ?", Date.today).order("events.event_date DESC").limit(5)
  end

  def upcoming_participations
    @upcoming_participations = @user.participations.joins(:event).where("event_date >= ?", Date.today).order("events.event_date ASC")
  end

  def past_participations
    @past_participations = @user.participations.joins(:event).where("event_date < ?", Date.today).order("events.event_date DESC")
  end

  def edit_profile

  end

  def update_profile

    if @user.update(profile_params)
      redirect_to users_dashboard_path, notice: "Profil mis à jour."
    else
      render :edit_profile, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :bio)
  end

  def set_user
    @user = current_user
  end
end
