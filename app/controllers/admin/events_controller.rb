class Admin::EventsController < Admin::ApplicationController
  before_action :set_event, only: [ :show, :update ]

  def index
    @events_query = Event.includes(:movie, :participations, :users)

    # Filters
    @events_query = @events_query.where(status: params[:status]) if params[:status].present?
    @events_query = @events_query.where(venue_name: params[:venue]) if params[:venue].present?
    @events_query = @events_query.joins(:movie).where(movies: { genre: params[:genre] }) if params[:genre].present?

    # Search
    if params[:q].present?
      @events_query = @events_query.where("title ILIKE ? OR venue_name ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
    end

    # Date filters
    case params[:date_filter]
    when "week"
      @events_query = @events_query.where(event_date: Date.today..Date.today.end_of_week)
    when "month"
      @events_query = @events_query.where(event_date: Date.today..Date.today.end_of_month)
    end

    @events = @events_query.order(event_date: :desc).limit(50).to_a

    # Stats
    @stats = {
      total: Event.count,
      upcoming: Event.where(status: :upcoming).count,
      completed: Event.where(status: :completed).count,
      sold_out: Event.where(status: :sold_out).count,
      cancelled: Event.where(status: :cancelled).count
    }

    # Filter options
    @venues = Event.distinct.pluck(:venue_name).compact.sort
    @genres = Movie.distinct.pluck(:genre).compact.sort
  end

  def show
    @participations = @event.participations.includes(:user).order(created_at: :desc).limit(20)
    @revenue = @event.participations.where(status: :confirmed).sum("price_cents * seats") / 100.0
  end

  def update
    case params[:status]
    when 'completed'
      mark_completed_action
    when 'cancelled'
      cancel_event_action
    else
      update_event_attributes
    end
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def mark_completed_action
    @event.update!(status: :completed)
    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Événement marqué comme terminé' } }
      format.html { redirect_to admin_events_path, notice: 'Événement terminé' }
    end
  end

  def cancel_event_action
    @event.update!(status: :cancelled)
    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Événement annulé' } }
      format.html { redirect_to admin_events_path, notice: 'Événement annulé' }
    end
  end

  def update_event_attributes
    if @event.update(event_params)
      redirect_to admin_event_path(@event), notice: 'Événement mis à jour'
    else
      render :show, alert: 'Erreur lors de la mise à jour'
    end
  end

  def event_params
    params.require(:event).permit(:title, :description, :venue_name, :venue_address, :event_date, :start_time, :max_capacity, :price_cents, :status)
  end
end
