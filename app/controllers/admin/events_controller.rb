class Admin::EventsController < Admin::ApplicationController
  def index
    @events = Event.includes(:movie, :participations)
  end

  def show
    @event = Event.find(params[:id])
  end

  def destroy
    @event = Event.find(params[:id])
    @event.destroy
    redirect_to admin_events_path
  end
end
