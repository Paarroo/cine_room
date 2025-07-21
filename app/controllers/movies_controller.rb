class MoviesController < ApplicationController
  before_action :set_movie, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_owner_or_admin!, only: [ :destroy ]

  def index
    # Start with approved movies only
    @movies = Movie.includes(:user, :events)
                   .where(validation_status: 'approved')

    # Apply simple filters if present
    @movies = @movies.where("title ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    @movies = @movies.where(genre: params[:genre]) if params[:genre].present?
    @movies = @movies.where(year: params[:year]) if params[:year].present?
    @movies = @movies.where(language: params[:language]) if params[:language].present?

    # Order by most recent
    @movies = @movies.order(created_at: :desc)

    # For filter dropdowns (optional)
    @genres = Movie.where(validation_status: 'approved').distinct.pluck(:genre).compact.sort
    @years = Movie.where(validation_status: 'approved').distinct.pluck(:year).compact.sort.reverse
    @languages = [ [ 'Français', 'fr' ], [ 'English', 'en' ], [ 'Español', 'es' ], [ 'Autre', 'other' ] ]
  end

  def show
    @related_events = @movie.events.upcoming.limit(3)
    @reviews = @movie.reviews.includes(:user).order(created_at: :desc).limit(5)
  end

  def new
    @movie = current_user.movies.build
  end

  def create
    @movie = current_user.movies.build(movie_params)

    if @movie.save
      redirect_to @movie, notice: 'Film bien déposé pour validation.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @movie.update(movie_params)
      redirect_to @movie, notice: 'La fiche du film a bien été mis à jour.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @movie.destroy!
    redirect_to movies_path, notice: 'La fiche du film a bien été supprimé.'
  end

  # Additional actions for filtering
  def search
    redirect_to movies_path(search: params[:q])
  end

  def by_genre
    redirect_to movies_path(genre: params[:genre])
  end

  def featured
    @movies = Movie.includes(:user, :events)
                   .where(validation_status: 'approved')
                   .joins(:events)
                   .group('movies.id')
                   .order('COUNT(events.id) DESC')
                   .limit(6)

    render :index
  end

  private

  def set_movie
    @movie = Movie.find(params[:id])
  end

  def ensure_owner_or_admin!
    unless current_user.admin? || @movie.user == current_user
      redirect_to movies_path, alert: 'Accès refusé.'
    end
  end

  def movie_params
    params.require(:movie).permit(:title, :synopsis, :director, :duration,
                                   :genre, :language, :year, :trailer_url, :poster_url)
  end
end
