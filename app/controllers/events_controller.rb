class EventsController < ApplicationController
  before_action :set_event, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_creator_or_admin!, except: [ :index, :show ]

  def index
     @events = Event.filter_by(params).includes(:movie, :created_by).order(event_date: :asc).page(params[:page])

    respond_to do |format|
      format.html
      format.turbo_stream { render partial: "events/results", formats: [:html] }
    end
  end

  def show
    # Only show approved events to regular users
    unless @event.approved? || (current_user && (current_user.admin? || @event.created_by == current_user))
      redirect_to events_path, alert: "Cet événement n'est pas disponible."
      return
    end
    
    @participation = current_user&.participations&.find_by(event: @event)
    @available_spots = @event.available_spots
    @movie = @event.movie
  end

  def new
    @event = Event.new
    @movies = current_user.admin? ? Movie.approved : current_user.movies.approved
  end

  def create
    @event = Event.new(event_params)
    @event.created_by = current_user
    
    # Set validation status based on user role
    if current_user.admin?
      @event.validation_status = 'approved'
      @event.validated_by = current_user
      @event.validated_at = Time.current
    else
      @event.validation_status = 'pending'
    end
    
    # Ensure creators can only create events for their own movies
    unless current_user.admin? || current_user.movies.approved.exists?(id: @event.movie_id)
      flash[:alert] = "Vous ne pouvez créer des événements que pour vos propres films approuvés."
      @movies = current_user.movies.approved
      render :new, status: :unprocessable_entity
      return
    end

    if @event.save
      if current_user.admin?
        redirect_to @event, notice: 'Événement créé et approuvé automatiquement.'
      else
        redirect_to events_path, notice: 'Événement proposé avec succès. Il sera visible après validation par un administrateur.'
      end
    else
      @movies = current_user.admin? ? Movie.approved : current_user.movies.approved
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @movies = current_user.admin? ? Movie.approved : current_user.movies.approved
  end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: 'Event was successfully updated.'
    else
      @movies = current_user.admin? ? Movie.approved : current_user.movies.approved
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy!
    redirect_to events_path, notice: 'Event was successfully deleted.'
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:movie_id, :title, :description, :venue_name,
                                   :venue_address, :event_date, :start_time,
                                   :max_capacity, :price_cents, :latitude, :longitude)
  end

end
