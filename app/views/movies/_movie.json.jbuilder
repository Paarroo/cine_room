json.extract! movie, :id, :title, :synopsis, :director, :duration, :genre, :language, :year, :trailer_url, :poster_url, :created_at, :updated_at
json.url movie_url(movie, format: :json)
