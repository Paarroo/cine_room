class Admin::EventsController < Admin::ApplicationController
  include EventManagement
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :export_participations, :send_notification ]

  def index
    @events_query = Event.includes(:movie, :participations, :users)
    @events_query = apply_filters(@events_query, params)
    @events = @events_query.order(event_date: :desc).limit(50).to_a

    # Calculate aggregate statistics for all events
    @stats = {
      total_events: @events.count,
      upcoming_events: @events.select { |e| e.event_date >= Date.current }.count,
      past_events: @events.select { |e| e.event_date < Date.current }.count,
      total_capacity: @events.sum(&:max_capacity),
      total_revenue: calculate_total_events_revenue(@events)
    }
    @venues = Event.distinct.pluck(:venue_name).compact.sort
    @genres = Movie.joins(:events).distinct.pluck(:genre).compact.sort
  end

  def show
    # Load participations with user information
    @participations = @event.participations.includes(:user).order(created_at: :desc)

    # Use event model methods for analytics (delegated to services)
    @revenue = @event.calculate_revenue
    @booking_analytics = @event.booking_analytics
    @recent_activities = @event.recent_activities
    @capacity_metrics = @event.capacity_metrics
  end

  def new
    @event = Event.new
    @movies = Movie.where(validation_status: :approved).order(:title)
  end

  def create
    @event = Event.new(event_params)

    if @event.save
      redirect_to admin_event_path(@event), notice: 'Événement créé avec succès.'
    else
      @movies = Movie.where(validation_status: :approved).order(:title)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @movies = Movie.where(validation_status: :approved).order(:title)
    @venues = Event.distinct.pluck(:venue_name).compact.sort
  end

  def destroy
    @event.destroy!
    redirect_to admin_events_path, notice: 'Événement supprimé avec succès.'
  end

  def update
    case params[:status]
    when 'completed'
      complete_event_action
    when 'cancelled'
      cancel_event_action
    when 'upcoming'
      reopen_event_action
    else
      # Regular event update
      update_event_attributes
    end
  end

  # Export participations to CSV
  def export_participations
    export_service = @event.export_service

    respond_to do |format|
      format.json do
        render json: export_service.export_response_data(format: :json)
      end
      format.csv do
        send_data export_service.generate_participations_csv,
                  filename: export_service.generate_export_filename
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { success: false, error: e.message } }
      format.html { redirect_to admin_event_path(@event), alert: 'Erreur lors de l\'export' }
    end
  end

  def send_notification
    notification_service = EventNotificationService.new(@event)
    notification_result = notification_service.send_event_notification

    respond_to do |format|
      format.json do
        if notification_result[:success]
          render json: {
            success: true,
            message: notification_result[:message],
            sent_count: notification_result[:sent_count]
          }
        else
          render json: { success: false, error: notification_result[:error] }
        end
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { success: false, error: e.message } }
    end
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def calculate_total_events_revenue(events)
    events.sum do |event|
      event.participations.where(status: [:confirmed, :attended])
           .sum { |p| (event.price_cents || 0) * p.seats }
    end / 100.0
  end

  # Complete event action with logging
  def complete_event_action
    @event.complete!
    log_event_action('completed', @event)

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Événement marqué comme terminé' } }
      format.html { redirect_to admin_event_path(@event), notice: 'Événement terminé avec succès' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_event_path(@event), alert: 'Erreur lors de la mise à jour' }
    end
  end

  # Cancel event action with logging
  def cancel_event_action
    @event.cancel!
    log_event_action('cancelled', @event)

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Événement annulé' } }
      format.html { redirect_to admin_event_path(@event), notice: 'Événement annulé' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_event_path(@event), alert: 'Erreur lors de l\'annulation' }
    end
  end

  # Reopen cancelled event
  def reopen_event_action
    @event.reopen!
    log_event_action('reopened', @event)

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Événement rouvert' } }
      format.html { redirect_to admin_event_path(@event), notice: 'Événement rouvert avec succès' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_event_path(@event), alert: 'Erreur lors de la réouverture' }
    end
  end


  # Update event attributes
  def update_event_attributes
    if @event.update(event_params)
      log_event_action('updated', @event, event_params.to_h)
      redirect_to admin_event_path(@event), notice: 'Événement mis à jour avec succès'
    else
      render :show, alert: 'Erreur lors de la mise à jour'
    end
  end




  # Enhanced logging with admin context
  def log_event_action(action, event, details = {})
    Rails.logger.info "Admin Event Management: #{current_user.email} #{action} event #{event.id} (#{event.title}) - #{details}"

    # RGPD
    # AuditLog.create(
    #   admin_user: current_user,
    #   action: action,
    #   target_type: 'Event',
    #   target_id: event.id,
    #   details: details.merge(event_title: event.title),
    #   ip_address: request.remote_ip,
    #   user_agent: request.user_agent
    # )
  end

  def apply_filters(query, params)
    query = query.where(status: params[:status]) if params[:status].present?
    query = query.where(venue_name: params[:venue]) if params[:venue].present?
    query = query.joins(:movie).where(movies: { genre: params[:genre] }) if params[:genre].present?
    
    if params[:q].present?
      query = query.where("title ILIKE ? OR venue_name ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
    end
    
    query
  end

  def event_params
    params.require(:event).permit(
      :title, :description, :venue_name, :venue_address, :country,
      :event_date, :start_time, :max_capacity, :price_cents,
      :status, :movie_id, :coordinates_verified
    )
  end
end
