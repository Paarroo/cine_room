class TicketsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_participation

  def show
    ensure_owner_or_admin!(@participation)
    
    @user = @participation.user
    @event = @participation.event
    @movie = @event.movie
    
    respond_to do |format|
      format.html # Show ticket page
      format.pdf do
        # Future implementation for PDF tickets
        redirect_to participation_ticket_path(@participation), 
                    alert: "Export PDF pas encore disponible"
      end
    end
  end

  private

  def set_participation
    @participation = Participation.find(params[:participation_id])
  end

  def ensure_owner_or_admin!(participation)
    unless participation.user == current_user || current_user&.admin?
      flash[:alert] = "Vous ne pouvez accéder qu'à vos propres billets."
      redirect_to root_path
    end
  end
end