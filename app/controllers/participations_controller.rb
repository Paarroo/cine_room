class ParticipationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_participation, only: [ :show, :destroy ]
  before_action :set_event, only: [ :create ]

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
    seats = participation_params[:seats].to_i

    if seats <= 0 || seats > @event.available_spots
      redirect_to new_event_participation_path(@event), alert: "Nombre de places invalide." and return
    end

    if current_user.participations.exists?(event: @event)
      redirect_to @event, alert: "Tu as déjà réservé une place pour cet événement." and return
    end

    session = Stripe::Checkout::Session.create(
      payment_method_types: [ 'card' ],
      line_items: [ {
        price_data: {
          currency: 'eur',
          unit_amount: @event.price_cents*100,
          product_data: {
            name: @event.title
          }
        },
        quantity: seats
      } ],
      metadata: {
        user_id: current_user.id,
        event_id: @event.id,
        seats: seats
      },
      mode: 'payment',
      success_url: "#{stripe_success_url}?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: stripe_cancel_url(event_id: @event.id)
    )

    redirect_to session.url, allow_other_host: true
  end

  def destroy
    @participation.destroy!
    redirect_to participations_path, notice: "Reservation cancelled successfully."
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
