class ReservationsController < ApplicationController
  before_action :authenticate_user!
  def show
    @participation = current_user.participations.find(params[:id])
    @event = @participation.event
  end
  
  def success
    @participation = Participation.find(params[:participation_id])
    @event = @participation.event
    unless @participation.user == current_user
  redirect_to root_path, alert: "Accès non autorisé." and return
   end
  end
end
