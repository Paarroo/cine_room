class ParticipationsController < ApplicationController
  before_action :set_participation, only: [ :show, :destroy ]
  before_action :set_event, only: [ :create ]

  def index
    @participations = current_user.participations
                                  .includes(event: :movie)
                                  .order(created_at: :desc)
  end

  def show
  end

  def create
    @participation = current_user.participations.build(event: @event)

    if @event.available_spots > 0
      if @participation.save
        ParticipationMailer.confirmation_email(@participation).deliver_later
        redirect_to @event, notice: 'Reservation successful!'
      else
        redirect_to @event, alert: @participation.errors.full_messages.join(', ')
      end
    else
      redirect_to @event, alert: 'No spots available.'
    end
  end

  def destroy
    event = @participation.event
    @participation.destroy!
    redirect_to event, notice: 'Reservation cancelled.'
  end

  private

  def set_participation
    @participation = current_user.participations.find(params[:id])
  end

  def set_event
    @event = Event.find(params[:event_id])
  end
end
