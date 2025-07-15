class PagesController < ApplicationController
  def home
    @creators = featured_creators
    @venues = featured_venues

    # Extracted stats in separated instance variables
    stats = home_stats
    @directors_count = stats[:directors_count]
    @movies_count    = stats[:movies_count]
    @venues_count    = stats[:venues_count]
    @events_count    = stats[:events_count]
  end

  def about
    
  end


  def contact
  end

  def legal
  end

  def privacy
  end

  def terms
  end

  private

  def featured_creators
    Creator.joins(:movies, :user)
          .where(movies: { validation_status: 'approved' })
          .group('creators.id', 'users.first_name', 'users.last_name')
          .select('creators.*, users.first_name, users.last_name, COUNT(movies.id) AS movies_count')
          .order('movies_count DESC')
          .limit(3)
  end


  def featured_venues
    Event.group(:venue_name, :venue_address)
         .select('venue_name, venue_address, MAX(max_capacity) as max_capacity, COUNT(*) as events_count')
         .order('events_count DESC')
         .limit(3)
         .map { |venue| venue.attributes.merge(venue_icon_data(venue.venue_name)) }
  end

  def home_stats
    {
      directors_count: Creator.verified.count,
      movies_count: Movie.approved.count,
      venues_count: Event.select(:venue_name, :venue_address).distinct.count,
      events_count: Event.upcoming.count
    }
  end

  def venue_icon_data(name)
    case name.downcase
    when /galerie/ then { icon: 'fas fa-palette', label: 'Galerie d\'art' }
    when /rooftop/ then { icon: 'fas fa-building', label: 'Rooftop' }
    when /hôtel|mansion/ then { icon: 'fas fa-home', label: 'Hôtel particulier' }
    else { icon: 'fas fa-map-marker-alt', label: 'Lieu unique' }
    end
  end
end
