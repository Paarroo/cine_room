module MoviesHelper

  def default_filter_options(resource)
    case resource
    when :movies
      {
        search: true,
        genres: Movie.approved.distinct.pluck(:genre).compact,
        years: Movie.approved.distinct.pluck(:year).compact.sort.reverse,
        directors: Movie.approved.distinct.pluck(:director).compact
      }
    when :events
      {
        search: true,
        genres: Movie.approved.distinct.pluck(:genre).compact,
        venues: Event.distinct.pluck(:venue_name).compact,
        date_filter: true
      }
    else
      {}
    end
  end

end
