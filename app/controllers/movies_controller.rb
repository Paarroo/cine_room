class MoviesController < ApplicationController
  before_action :set_movie, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_owner_or_admin!, only: [ :destroy ]

  def index
    @movies = @q.result.includes(:user, :events)
                 .where(validation_status: 'approved')
                 .order(created_at: :desc)
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
    redirect_to movies_path, notice: 'La fiche du film à bien été supprimé.'
  end

  private

  def set_movie
    @movie = Movie.find(params[:id])
  end

  def ensure_owner_or_admin!
    unless current_user.admin? || @movie.creator == current_user
      redirect_to movies_path, alert: 'Accès refusé.'
    end
  end

  def movie_params
    params.require(:movie).permit(:title, :synopsis, :director, :duration,
                                   :genre, :language, :year, :trailer_url, :poster_url)
  end
end
