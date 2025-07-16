class StripeCheckoutController < ApplicationController
  before_action :authenticate_user!

  def success
    @event = Event.find(params[:event_id])
    seats = params[:seats].to_i
    stripe_session_id = params[:session_id]

    # Prevent duplicate participation
    if current_user.participations.exists?(event: @event)
      redirect_to @event, alert: "You have already booked a seat for this event."
      return
    end

    # Create the participation
    participation = current_user.participations.create!(
      event: @event,
      seats: seats,
      stripe_payment_id: stripe_session_id,
      status: :paid
    )

    ParticipationMailer.confirmation_email(participation).deliver_later

    redirect_to @event, notice: "Thanks for your booking! Your payment was successful."
  end

  def cancel
    @event = Event.find(params[:event_id])
    redirect_to @event, alert: "Payment was canceled. No reservation has been made."
  end
end