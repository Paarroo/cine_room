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

      User.joins(creator: :movies)
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
      directors_count: User.creator.count,
      movies_count: Movie.approved.count,
      venues_count: Event.select(:venue_name, :venue_address).distinct.count,
      events_count: Event.upcoming.count
    }

  end
end
