class MoviesController < ApplicationController
  before_action :set_movie, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_creator_or_admin!, except: [ :index, :show ]
  before_action :ensure_owner_or_admin!, only: [ :edit, :update, :destroy ]

  def index
    @movies = Movie.includes(:creator, :events)
                   .where(validation_status: 'approved')
                   .order(created_at: :desc)
  end

  def show
    @related_events = @movie.events.upcoming.limit(3)
    @reviews = @movie.reviews.includes(:user).order(created_at: :desc).limit(5)
  end

  def new
    @movie = current_user.creator.movies.build
  end

  def create
    @movie = current_user.creator.movies.build(movie_params)

    if @movie.save
      redirect_to @movie, notice: 'Movie submitted for validation.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @movie.update(movie_params)
      redirect_to @movie, notice: 'Movie was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @movie.destroy!
    redirect_to movies_path, notice: 'Movie was successfully deleted.'
  end

  private

  def set_movie
    @movie = Movie.find(params[:id])
  end

  def ensure_owner_or_admin!
    unless current_user.admin? || @movie.creator.user == current_user
      redirect_to movies_path, alert: 'Access denied.'
    end
  end

  def movie_params
    params.require(:movie).permit(:title, :synopsis, :director, :duration,
                                   :genre, :language, :year, :trailer_url, :poster_url)
  end
end
