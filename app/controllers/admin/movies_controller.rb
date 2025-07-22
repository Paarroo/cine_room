class Admin::MoviesController < Admin::ApplicationController
  before_action :set_movie, only: [ :show, :validate_movie, :reject_movie ]

  def index
    @movies = Movie.includes(:user, :events)
                   .filter_by_status(params[:status])
                   .filter_by_genre(params[:genre])
                   .filter_by_year(params[:year])
                   .search(params[:q])
                   .order(created_at: :desc)
                   .page(params[:page])
                   .per(20)

    @stats = {
      total: Movie.count,
      pending: Movie.where(validation_status: :pending).count,
      approved: Movie.where(validation_status: :approved).count,
      rejected: Movie.where(validation_status: :rejected).count
    }

    @genres = Movie.distinct.pluck(:genre).compact.sort
    @years = Movie.distinct.pluck(:year).compact.sort.reverse
  end

  def show
    @events = @movie.events.includes(:participations).order(event_date: :desc)
    @reviews = @movie.reviews.includes(:user, :event).order(created_at: :desc).limit(10)
  end

  # AJAX endpoint for validation
  def validate_movie
    if @movie.update(
      validation_status: :approved,
      validated_by: current_user,
      validated_at: Time.current
    )
      respond_to do |format|
        format.json { render json: { status: 'success', message: 'Film validé avec succès' } }
        format.html { redirect_to admin_movies_path, notice: 'Film validé avec succès' }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', message: 'Erreur lors de la validation' } }
        format.html { redirect_to admin_movies_path, alert: 'Erreur lors de la validation' }
      end
    end
  end

  def reject_movie
    if @movie.update(
      validation_status: :rejected,
      validated_by: current_user,
      validated_at: Time.current
    )
      respond_to do |format|
        format.json { render json: { status: 'success', message: 'Film rejeté' } }
        format.html { redirect_to admin_movies_path, notice: 'Film rejeté' }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', message: 'Erreur lors du rejet' } }
        format.html { redirect_to admin_movies_path, alert: 'Erreur lors du rejet' }
      end
    end
  end

  # Bulk actions for multiple movies
  def bulk_validate
    movie_ids = params[:movie_ids] || []

    Movie.where(id: movie_ids).update_all(
      validation_status: :approved,
      validated_by_id: current_user.id,
      validated_at: Time.current
    )

    respond_to do |format|
      format.json { render json: { status: 'success', message: "#{movie_ids.count} films validés" } }
      format.html { redirect_to admin_movies_path, notice: "#{movie_ids.count} films validés" }
    end
  end

  def bulk_reject
    movie_ids = params[:movie_ids] || []

    Movie.where(id: movie_ids).update_all(
      validation_status: :rejected,
      validated_by_id: current_user.id,
      validated_at: Time.current
    )

    respond_to do |format|
      format.json { render json: { status: 'success', message: "#{movie_ids.count} films rejetés" } }
      format.html { redirect_to admin_movies_path, notice: "#{movie_ids.count} films rejetés" }
    end
  end

  private

  def set_movie
    @movie = Movie.find(params[:id])
  end
end

# Add these scopes to the Movie model (app/models/movie.rb)
class Movie < ApplicationRecord
  # ... existing code ...

  scope :filter_by_status, ->(status) {
    return all unless status.present?
    where(validation_status: status)
  }

  scope :filter_by_genre, ->(genre) {
    return all unless genre.present?
    where(genre: genre)
  }

  scope :filter_by_year, ->(year) {
    return all unless year.present?
    where(year: year)
  }

  scope :search, ->(query) {
    return all unless query.present?
    where("title ILIKE ? OR director ILIKE ?", "%#{query}%", "%#{query}%")
  }
end
