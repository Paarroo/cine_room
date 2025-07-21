class Users::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show
    @user = current_user
    @upcoming_participations = @user.participations.upcoming.includes(:event)
    @past_participations = @user.participations.past.includes(:event)
    @published_movies = @user.movies
    
    if @user.creator?
      @created_events = @user.created_events
    end
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
      redirect_to users_dashboard_path(current_user), notice: "Profil mis à jour."
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
