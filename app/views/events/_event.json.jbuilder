json.extract! event, :id, :movie_id, :title, :description, :venue_name, :venue_address, :event_date, :start_time, :max_capacity, :price_cents, :status, :created_at, :updated_at
json.url event_url(event, format: :json)
