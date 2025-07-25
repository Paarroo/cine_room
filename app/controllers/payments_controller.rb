class PaymentsController < ApplicationController
  before_action :authenticate_user!

  # Create Stripe checkout session
  def create
    @event = Event.find(params[:event_id])
    seats = params[:seats].to_i

    # Validate request
    unless seats > 0 && seats <= 5
      redirect_to @event, alert: "Nombre de places invalide (1-5)." and return
    end

    # Check if user already has a participation for this event
    if current_user.participations.exists?(event: @event)
      redirect_to @event, alert: "Tu as déjà réservé une place pour cet événement." and return
    end

    begin
      # Create Stripe checkout session with metadata for webhooks
      checkout_service = StripeCheckoutService.new(@event, current_user, seats)
      session = checkout_service.create_checkout_session

      # Redirect to Stripe checkout
      redirect_to session.url, allow_other_host: true
      
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error: #{e.message}"
      redirect_to @event, alert: "Erreur de paiement. Veuillez réessayer." and return
    rescue => e
      Rails.logger.error "Payment error: #{e.message}"
      redirect_to @event, alert: "Une erreur est survenue. Veuillez réessayer." and return
    end
  end
end