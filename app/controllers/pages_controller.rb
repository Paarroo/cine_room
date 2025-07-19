class PagesController < ApplicationController
  def home
    @creators = featured_creators
    @events   = featured_events

    stats = home_stats
    @directors_count = stats[:directors_count]
    @movies_count    = stats[:movies_count]
    @venues_count    = stats[:venues_count]
    @events_count    = stats[:events_count]
  end

  def about; end
  def contact; end
  def legal; end
  def privacy; end
  def terms; end

  private

  def featured_creators
    User.where(id: Movie.approved.select(:creator_id).distinct)
        .joins("LEFT JOIN movies ON movies.creator_id = users.id")
        .where(movies: { validation_status: :approved })
        .group('users.id')
        .select('users.*, COUNT(movies.id) AS movies_count')
        .order('movies_count DESC')
        .limit(3)
  end

  def featured_events
    Event.includes(:movie)
         .upcoming
         .order(event_date: :asc)
         .limit(3)
  end

  def home_stats
    {
      directors_count: User.joins("INNER JOIN movies ON movies.creator_id = users.id").distinct.count,
      movies_count: Movie.where(validation_status: Movie.validation_statuses[:approved]).count,
      venues_count: Event.select(:venue_name, :venue_address).distinct.count,
      events_count: Event.where(status: Event.statuses[:upcoming]).count
    }
  end
end
