module MovieValidation
  extend ActiveSupport::Concern

  def validate_movie_action(movie)
    movie.update!(
      validation_status: :approved,
      validated_by: current_user,
      validated_at: Time.current
    )
  end

  def reject_movie_action(movie)
    movie.update!(
      validation_status: :rejected,
      validated_by: current_user,
      validated_at: Time.current
    )
  end

  def bulk_validate_movies(movie_ids)
    Movie.where(id: movie_ids).update_all(
      validation_status: :approved,
      validated_by_id: current_user.id,
      validated_at: Time.current
    )
  end

  def bulk_reject_movies(movie_ids)
    Movie.where(id: movie_ids).update_all(
      validation_status: :rejected,
      validated_by_id: current_user.id,
      validated_at: Time.current
    )
  end

  def calculate_movie_stats
    {
      total: Movie.count,
      pending: Movie.where(validation_status: :pending).count,
      approved: Movie.where(validation_status: :approved).count,
      rejected: Movie.where(validation_status: :rejected).count
    }
  end

  def filter_movies(params)
    movies = Movie.includes(:user, :events)

    movies = movies.where(validation_status: params[:status]) if params[:status].present?
    movies = movies.where(genre: params[:genre]) if params[:genre].present?
    movies = movies.where(year: params[:year]) if params[:year].present?

    if params[:q].present?
      movies = movies.where("title ILIKE ? OR director ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
    end

    movies.order(created_at: :desc)
  end
end
