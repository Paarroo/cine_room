class MoviesController < ApplicationController
  before_action :set_movie, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_owner_or_admin!, only: [ :edit, :update,:destroy ]
  before_action :authorize_editing, only: [:edit, :update, :destroy]

  def index
    @movies = Movie.filter_by(params).order(year: :asc).page(params[:page])
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
    @movie.director = current_user.full_name

    begin
      if @movie.save
        redirect_to @movie, notice: 'Film publié pour validation.'
      else
        render :new, status: :unprocessable_entity
      end
    rescue SolidQueue::Job::EnqueueError => e
      # Handle background job failure gracefully
      Rails.logger.warn "Background job failed for movie #{@movie.id}: #{e.message}"
      
      if @movie.persisted?
        redirect_to @movie, notice: 'Film publié pour validation. (Analyse d\'image en cours en arrière-plan)'
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit
  end

  def update
    if @movie.update(movie_params)
      @movie.update(director: current_user.full_name)
      redirect_to @movie, notice: 'La fiche du film a bien été mis à jour.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @movie.destroy!
    redirect_to users_dashboard_path(current_user), notice: 'La fiche du film à bien été supprimé.'
  end

  private

  def authorize_editing
    if @movie.approved? && !current_user.admin?
      redirect_to @movie, alert: "Ce film est approuvé et ne peut plus être modifié."
    end
  end

  def set_movie
    @movie = Movie.find(params[:id])
  end

  def ensure_owner_or_admin!
    unless current_user.admin? || @movie.user == current_user
      redirect_to movies_path, alert: 'Accès refusé.'
    end
  end

  def movie_params
    params.require(:movie).permit(:title, :synopsis, :duration,
                                   :genre, :language, :year, :trailer_url, :poster_url, :authorship_confirmed, :poster)
  end

  def filter_movies(scope)
    scope = scope.where(genre: params[:genre]) if params[:genre].present?

    if params[:year].present?
      scope = scope.where(year: params[:year].to_i)
    end

    if params[:q].present?
      query = "%#{params[:q].downcase}%"
      scope = scope.where("LOWER(title) LIKE :q OR LOWER(director) LIKE :q", q: query)
    end

    scope
  end
end
