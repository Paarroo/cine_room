class Admin::MoviesController < Admin::ApplicationController
  before_action :set_movie, only: [ :show, :update, :validate, :reject ]

  def index
    @movies_query = Movie.includes(:user, :events, :reviews)

    @movies_query = @movies_query.where(validation_status: params[:status]) if params[:status].present?
    @movies_query = @movies_query.where(genre: params[:genre]) if params[:genre].present?
    @movies_query = @movies_query.where(year: params[:year]) if params[:year].present?

    if params[:q].present?
      @movies_query = @movies_query.where("title ILIKE ? OR director ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
    end

    @movies = @movies_query.order(created_at: :desc).limit(50).to_a

    # Calculate stats
    @stats = {
      total: Movie.count,
      pending: Movie.where(validation_status: :pending).count,
      approved: Movie.where(validation_status: :approved).count,
      rejected: Movie.where(validation_status: :rejected).count
    }

    # Get filter options
    @genres = Movie.distinct.pluck(:genre).compact.sort
    @years = Movie.distinct.pluck(:year).compact.sort.reverse
  end

  def show
    @events = @movie.events.includes(:participations).order(event_date: :desc)
    @reviews = @movie.reviews.includes(:user, :event).order(created_at: :desc).limit(10)
  end

  #  Update action
  def update
    case params[:status]
    when 'approved'
      validate_movie_action
    when 'rejected'
      reject_movie_action
    else
      # Regular movie update
      update_movie_attributes
    end
  end

  # Validate action for RESTful route
  def validate
    @movie.update!(
      validation_status: :approved,
      validated_by: current_user,
      validated_at: Time.current
    )

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Film validé avec succès' } }
      format.html { redirect_to admin_movies_path, notice: 'Film validé avec succès' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_movies_path, alert: 'Erreur lors de la validation' }
    end
  end

  # Reject action for RESTful route
  def reject
    @movie.update!(
      validation_status: :rejected,
      validated_by: current_user,
      validated_at: Time.current
    )

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Film rejeté' } }
      format.html { redirect_to admin_movies_path, notice: 'Film rejeté' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_movies_path, alert: 'Erreur lors du rejet' }
    end
  end

  private

  def set_movie
    @movie = Movie.find(params[:id])
  end

  def validate_movie_action
    @movie.update!(
      validation_status: :approved,
      validated_by: current_user,
      validated_at: Time.current
    )

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Film validé avec succès' } }
      format.html { redirect_to admin_movies_path, notice: 'Film validé avec succès' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_movies_path, alert: 'Erreur lors de la validation' }
    end
  end

  def reject_movie_action
    @movie.update!(
      validation_status: :rejected,
      validated_by: current_user,
      validated_at: Time.current
    )

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Film rejeté' } }
      format.html { redirect_to admin_movies_path, notice: 'Film rejeté' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_movies_path, alert: 'Erreur lors du rejet' }
    end
  end

  def update_movie_attributes
    if @movie.update(movie_params)
      redirect_to admin_movie_path(@movie), notice: 'Film mis à jour avec succès'
    else
      render :show, alert: 'Erreur lors de la mise à jour'
    end
  end

  def movie_params
    params.require(:movie).permit(:title, :synopsis, :director, :duration, :genre, :year, :validation_status)
  end
end
