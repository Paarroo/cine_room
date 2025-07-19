class Admin::ParticipationsController < Admin::ApplicationController
  def index
    @participations = Participation.includes(:user, :event)
  end

  def destroy
    @participation = Participation.find(params[:id])
    @participation.destroy
    redirect_to admin_participations_path
  end
end
