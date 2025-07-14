class PagesController < ApplicationController

  def home
    @creators = Movie
      .where.not(director: [nil, ""])
      .group(:director)
      .select("director, COUNT(*) AS movie_count")
      .order("movie_count DESC")

    @venues = Event
    .group(:venue_name, :venue_address)
    .select(
      "venue_name AS name",
      "venue_address AS address",
      "MAX(max_capacity) AS capacity",
      "COUNT(*) AS events_count"
    )
    .map { |venue| venue.attributes.symbolize_keys.merge(icon_label_for_venue(venue[:name])) }
      
  end

  private

  def icon_label_for_venue(name)
    case name.downcase
    when /galerie/
      { icon: "fas fa-palette", label: "Galerie d'art", color: "cinema-blue" }
    when /rooftop/
      { icon: "fas fa-building", label: "Rooftop", color: "indigo" }
    when /hôtel|mansion|manoir/
      { icon: "fas fa-home", label: "Hôtel particulier", color: "emerald" }
    else
      { icon: "fas fa-map-marker-alt", label: "Lieu d'exception", color: "gray" }
    end
  end

end
