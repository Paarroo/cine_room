class ReservationsController < ApplicationController
  before_action :authenticate_user!
  def show
    @participation = current_user.participations.find(params[:id])
    @event = @participation.event
  end
  
  def success
    @participation = Participation.find(params[:participation_id])
    @event = @participation.event
  end
end
