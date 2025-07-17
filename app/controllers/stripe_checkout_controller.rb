class StripeCheckoutController < ApplicationController
  before_action :authenticate_user!

  def success
    session_id = params[:session_id]

    begin
      stripe_session = Stripe::Checkout::Session.retrieve(session_id)
    rescue Stripe::InvalidRequestError => e
      redirect_to root_path, alert: "Session introuvable." and return
    end

    event_id = stripe_session.metadata.event_id
    seats = stripe_session.metadata.seats.to_i
    @event = Event.find(event_id)

    if current_user.participations.exists?(event: @event)
      redirect_to @event, alert: "Tu as déjà réservé une place pour cet événement." and return
    end

    participation = current_user.participations.create!(
      event: @event, 
      seats: seats,
      stripe_payment_id: session_id,
      status: :confirmed
    )

    ParticipationMailer.confirmation_email(participation).deliver_later

    redirect_to @event, notice: "Merci pour ta réservation ! Paiement confirmé."
  end

  def cancel
    @event = Event.find(params[:event_id])
    redirect_to @event, alert: "Le paiement a été annulé."
  end
end
