json.extract! creator, :id, :user_id, :bio, :status, :verified_at, :created_at, :updated_at
json.url creator_url(creator, format: :json)
