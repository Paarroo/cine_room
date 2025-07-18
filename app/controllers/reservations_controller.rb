class ReservationsController < ApplicationController
  before_action :authenticate_user!

  def success
    @participation = Participation.find(params[:participation_id])
    @event = @participation.event
  end
end
