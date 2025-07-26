class Webhooks::StripeController < ApplicationController
  # Skip CSRF protection for Stripe webhooks
  skip_before_action :verify_authenticity_token
  
  # Webhook endpoint for Stripe events
  def receive
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']

    begin
      # Verify webhook signature
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError
      render json: { error: 'Invalid payload' }, status: 400
      return
    rescue Stripe::SignatureVerificationError
      render json: { error: 'Invalid signature' }, status: 400
      return
    end

    # Handle the event
    case event['type']
    when 'checkout.session.completed'
      handle_checkout_session_completed(event['data']['object'])
    when 'payment_intent.succeeded'
      handle_payment_succeeded(event['data']['object'])
    when 'payment_intent.payment_failed'
      handle_payment_failed(event['data']['object'])
    else
      Rails.logger.info "Unhandled Stripe event type: #{event['type']}"
    end

    render json: { status: 'success' }, status: 200
  end

  private

  # Handle completed checkout session
  def handle_checkout_session_completed(session)
    Rails.logger.info "Processing checkout session: #{session['id']}"
    
    # Extract metadata from session
    event_id = session['metadata']['event_id']
    user_id = session['metadata']['user_id'] 
    seats = session['metadata']['seats'].to_i

    return unless event_id && user_id && seats > 0

    event = Event.find_by(id: event_id)
    user = User.find_by(id: user_id)

    return unless event && user

    # Check if participation already exists (avoid duplicates)
    existing_participation = user.participations.find_by(
      event: event,
      stripe_payment_id: session['id']
    )

    return if existing_participation

    # Create confirmed participation
    participation = user.participations.create!(
      event: event,
      seats: seats,
      stripe_payment_id: session['id'],
      status: :confirmed
    )

    # Send ticket with QR code
    TicketMailer.ticket_confirmation(participation).deliver_later
    
    Rails.logger.info "Participation created via webhook: #{participation.id}"
  rescue => e
    Rails.logger.error "Error processing checkout session: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  # Handle successful payment
  def handle_payment_succeeded(payment_intent)
    Rails.logger.info "Payment succeeded: #{payment_intent['id']}"
    # Additional logic if needed
  end

  # Handle failed payment
  def handle_payment_failed(payment_intent)
    Rails.logger.error "Payment failed: #{payment_intent['id']}"
    # Handle failed payments (notify user, clean up, etc.)
  end
end