class StripeCheckoutController < ApplicationController
  before_action :authenticate_user!

  def success
    session_id = params[:session_id]

    begin
      stripe_session = Stripe::Checkout::Session.retrieve(session_id)
    rescue Stripe::InvalidRequestError
      redirect_to root_path, alert: "Session introuvable." and return
    end

    event_id = stripe_session.metadata.event_id
    seats     = stripe_session.metadata.seats.to_i
    @event    = Event.find(event_id)

    unless stripe_session.payment_status == "paid"
      redirect_to root_path, alert: "Le paiement n'a pas été confirmé." and return
    end

    # Check if participation already exists (created by webhook)
    participation = current_user.participations.find_by(
      event: @event,
      stripe_payment_id: session_id
    )

    # If not created by webhook, create it now (fallback)
    unless participation
      if current_user.participations.exists?(event: @event)
        redirect_to @event, alert: "Tu as déjà réservé une place pour cet événement." and return
      end

      participation = current_user.participations.create!(
        event: @event,
        seats: seats,
        stripe_payment_id: session_id,
        status: :confirmed
      )

      TicketMailer.ticket_confirmation(participation).deliver_now
      Rails.logger.info "Participation created via success redirect (webhook missed): #{participation.id}"
    else
      Rails.logger.info "Participation already exists from webhook: #{participation.id}"
    end

    redirect_to reservation_success_path(participation_id: participation.id)
  end

  def cancel
    @event = Event.find(params[:event_id])
    redirect_to @event, alert: "Le paiement a été annulé."
  end
end
