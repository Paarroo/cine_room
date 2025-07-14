class EventsController < ApplicationController
  before_action :set_event, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_admin!, except: [ :index, :show ]

  def index
    @events = Event.includes(:movie)
                   .upcoming
                   .order(:event_date)

    @events = @events.joins(:movie).where(movies: { genre: params[:genre] }) if params[:genre].present?
    @events = @events.where(venue_name: params[:venue]) if params[:venue].present?
  end

  def show
    @participation = current_user&.participations&.find_by(event: @event)
    @available_spots = @event.available_spots
    @movie = @event.movie
  end

  def new
    @event = Event.new
    @movies = Movie.approved
  end

  def create
    @event = Event.new(event_params)

    if @event.save
      redirect_to @event, notice: 'Event was successfully created.'
    else
      @movies = Movie.approved
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @movies = Movie.approved
  end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: 'Event was successfully updated.'
    else
      @movies = Movie.approved
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
