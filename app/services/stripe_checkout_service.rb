class StripeCheckoutService
  def initialize(event, user, seats)
    @event = event
    @user = user
    @seats = seats.to_i
  end

  # Create Stripe checkout session with proper metadata for webhooks
  def create_checkout_session
    Stripe::Checkout::Session.create({
      payment_method_types: ['card'],
      line_items: [{
        price_data: {
          currency: 'eur',
          product_data: {
            name: @event.title,
            description: "Projection le #{I18n.l(@event.event_date, format: :long)}"
          },
          unit_amount: @event.price_cents
        },
        quantity: @seats
      }],
      mode: 'payment',
      success_url: stripe_success_url(session_id: '{CHECKOUT_SESSION_ID}'),
      cancel_url: stripe_cancel_url(event_id: @event.id),
      metadata: {
        event_id: @event.id.to_s,
        user_id: @user.id.to_s,
        seats: @seats.to_s
      }
    })
  end

  private

  # Helper methods for URL generation
  def stripe_success_url(session_id:)
    Rails.application.routes.url_helpers.stripe_success_url(
      session_id: session_id,
      host: Rails.application.config.action_mailer.default_url_options[:host]
    )
  end

  def stripe_cancel_url(event_id:)
    Rails.application.routes.url_helpers.stripe_cancel_url(
      event_id: event_id,
      host: Rails.application.config.action_mailer.default_url_options[:host]
    )
  end
end