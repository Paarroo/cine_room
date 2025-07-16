class ParticipationsController < ApplicationController
  before_action :authenticate_user!  
  before_action :set_participation, only: [:show, :destroy]
  before_action :set_event, only: [:create]

  def index
    @participations = current_user.participations
                                  .includes(event: :movie)
                                  .order(created_at: :desc)
  end

  def show
  end

  def new
    @event = Event.find(params[:event_id])
    @participation = Participation.new
  end

  def create
    @event = Event.find(params[:event_id])

    
    if current_user.participations.exists?(event: @event)
      redirect_to @event, alert: "Tu as déjà réservé une place pour cet événement."
      return
    end

    @participation = current_user.participations.build(
      event: @event,
      seats: participation_params[:seats]
    )

    if @event.available_spots >= @participation.seats.to_i
      if @participation.save
        ParticipationMailer.confirmation_email(@participation).deliver_later
        redirect_to @event, notice: 'Réservation confirmée !'
      else
        redirect_to @event, alert: @participation.errors.full_messages.join(', ')
      end
    else
      redirect_to @event, alert: 'Il ne reste pas assez de places disponibles.'
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

  def participation_params
    params.require(:participation).permit(:seats)
  end
end
