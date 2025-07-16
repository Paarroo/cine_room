class StripeCheckoutController < ApplicationController
  before_action :authenticate_user!

  def success
    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    event_id = session.metadata.event_id
    seats = session.metadata.seats.to_i

    @event = Event.find(event_id)

    if current_user.participations.exists?(event: @event)
      redirect_to @event, alert: "You have already booked a seat for this event."
      return
    end

    participation = current_user.participations.create!(
      event: @event,
      seats: seats,
      stripe_payment_id: session.id,
      status: :paid
    )

    ParticipationMailer.confirmation_email(participation).deliver_later

    redirect_to @event, notice: "Thanks for your booking! Your payment was successful."
  end

  def cancel
    redirect_to root_path, alert: "Payment was canceled. No reservation has been made."
  end
end
