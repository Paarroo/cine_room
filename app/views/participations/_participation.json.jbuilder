json.extract! participation, :id, :user_id, :event_id, :stripe_payment_id, :status, :created_at, :updated_at
json.url participation_url(participation, format: :json)
