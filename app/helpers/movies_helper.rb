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


    def safe_movie_card(movie)
      return '' if movie.nil? || !movie.respond_to?(:id)
      render 'movie_card', movie: movie
    rescue => e
      Rails.logger.error "Movie card render error: #{e.message}"
      render 'movie_card_error', movie: movie
    end

    def safe_movie_title(movie)
      safe_attr(movie, :title, 'Film sans titre')
    end

    def safe_movie_director(movie)
      safe_attr(movie, :director, 'Réalisateur inconnu')
    end

    def safe_movie_year(movie)
      safe_attr(movie, :year, Date.current.year)
    end

    def safe_movie_duration(movie)
      safe_attr(movie, :duration, 0)
    end

    def safe_movie_genre(movie)
      safe_attr(movie, :genre, 'Genre non défini')
    end

    def safe_movie_synopsis(movie)
      safe_attr(movie, :synopsis, 'Aucun synopsis disponible')
    end

    def safe_movie_validation_status(movie)
      safe_attr(movie, :validation_status, 'pending')
    end

    def safe_movie_creator(movie)
      return 'Utilisateur inconnu' if movie.nil? || movie.user.nil?
      safe_attr(movie.user, :full_name, 'Utilisateur sans nom')
    end

    def safe_movie_events_count(movie)
      return 0 if movie.nil? || !movie.respond_to?(:events)
      movie.events&.count || 0
    end

    def safe_movie_reviews_count(movie)
      return 0 if movie.nil? || !movie.respond_to?(:reviews)
      movie.reviews&.count || 0
    end

    def movie_status_badge(movie)
      status = safe_movie_validation_status(movie)

      case status.to_s
      when 'pending'
        content_tag :span, class: "px-3 py-1 bg-yellow-500/20 text-yellow-300 rounded-full text-xs font-medium" do
          '<i class="fas fa-clock mr-1"></i>En attente'.html_safe
        end
      when 'approved'
        content_tag :span, class: "px-3 py-1 bg-green-500/20 text-green-300 rounded-full text-xs font-medium" do
          '<i class="fas fa-check mr-1"></i>Validé'.html_safe
        end
      when 'rejected'
        content_tag :span, class: "px-3 py-1 bg-red-500/20 text-red-300 rounded-full text-xs font-medium" do
          '<i class="fas fa-times mr-1"></i>Rejeté'.html_safe
        end
      else
        content_tag :span, class: "px-3 py-1 bg-gray-500/20 text-gray-300 rounded-full text-xs font-medium" do
          '<i class="fas fa-question mr-1"></i>Inconnu'.html_safe
        end
      end
    end
    def default_filter_options(resource)
        case resource
        when :movies
          {
            search: true,
            genres: Movie.approved.distinct.pluck(:genre).compact,
            years: Movie.approved.distinct.pluck(:year).compact.sort.reverse,
            directors: Movie.approved.distinct.pluck(:director).compact
          }
        else
          {}
        end
      end
end
