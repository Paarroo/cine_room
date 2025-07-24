class Admin::EventsController < Admin::ApplicationController
  include EventManagement
  before_action :set_event, only: [ :show, :update, :export_participations, :send_notification ]

  def index
    @events_query = Event.includes(:movie, :participations, :users)

    # Apply filters
    @events_query = @events_query.where(status: params[:status]) if params[:status].present?
    @events_query = @events_query.where(venue_name: params[:venue]) if params[:venue].present?
    @events_query = @events_query.joins(:movie).where(movies: { genre: params[:genre] }) if params[:genre].present?

    # Search functionality
    if params[:q].present?
      @events_query = @events_query.where("title ILIKE ? OR venue_name ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
    end

    @events = @events_query.order(event_date: :desc).limit(50).to_a

    # Calculate comprehensive stats
    @stats = {
      total: Event.count,
      upcoming: Event.where(status: :upcoming).count,
      completed: Event.where(status: :completed).count,
      sold_out: Event.where(status: :sold_out).count,
      cancelled: Event.where(status: :cancelled).count
    }

    # Get filter options for dropdowns
    @venues = Event.distinct.pluck(:venue_name).compact.sort
    @genres = Movie.joins(:events).distinct.pluck(:genre).compact.sort
  end

  def show
    # Load participations with user information
    @participations = @event.participations.includes(:user).order(created_at: :desc)

    # Calculate event revenue
    @revenue = calculate_event_revenue(@event)

    # Calculate booking analytics
    @booking_analytics = calculate_booking_analytics(@event)

    # Get recent activities for this event
    @recent_activities = get_event_activities(@event)

    # Calculate capacity metrics
    @capacity_metrics = calculate_capacity_metrics(@event)
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
    @export_data = export_event_participations(@event)

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          data: @export_data,
          filename: "event_#{@event.id}_participations_#{Date.current.strftime('%Y%m%d')}.csv",
          download_url: admin_event_export_participations_path(@event, format: :csv)
        }
      end
      format.csv do
        send_data generate_participations_csv(@export_data),
                  filename: "event_#{@event.id}_participations_#{Date.current.strftime('%Y%m%d')}.csv"
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { success: false, error: e.message } }
      format.html { redirect_to admin_event_path(@event), alert: 'Erreur lors de l\'export' }
    end
  end

  # Send notification to all event participants
  def send_notification
    notification_result = send_event_notification(@event)

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

  # Complete event action with logging
  def complete_event_action
    @event.update!(
      status: :completed,
      updated_at: Time.current
    )

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
    @event.update!(
      status: :cancelled,
      updated_at: Time.current
    )

    # Cancel all pending participations
    @event.participations.where(status: :pending).update_all(status: :cancelled)

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
    @event.update!(
      status: :upcoming,
      updated_at: Time.current
    )

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

  def edit
      # @event already set by before_action
      # Prepare form data if needed
      @movies = Movie.where(validation_status: :approved).order(:title)
      @venues = Event.distinct.pluck(:venue_name).compact.sort
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

  # Calculate event revenue from confirmed participations
  def calculate_event_revenue(event)
    event.participations.where(status: [ :confirmed, :attended ])
         .sum("#{event.price_cents} * participations.seats") / 100.0
  end

  # Calculate booking analytics for event
  def calculate_booking_analytics(event)
    participations = event.participations.where(status: [ :confirmed, :attended ])

    {
      total_bookings: participations.count,
      total_seats_sold: participations.sum(:seats),
      average_booking_size: participations.average(:seats)&.round(1) || 0,
      booking_conversion_rate: calculate_booking_conversion_rate(event),
      daily_bookings: calculate_daily_bookings(event)
    }
  end

  # Get recent activities for event
  def get_event_activities(event)
    activities = []

    # Recent participations
    event.participations.includes(:user)
         .order(created_at: :desc)
         .limit(5)
         .each do |participation|
      activities << {
        type: 'participation',
        title: 'Nouvelle réservation',
        description: "#{participation.user&.full_name} - #{participation.seats} place(s)",
        status: participation.status,
        created_at: participation.created_at
      }
    end

    activities.sort_by { |a| a[:created_at] }.reverse
  end

  # Calculate capacity metrics
  def calculate_capacity_metrics(event)
    confirmed_seats = event.participations.where(status: [ :confirmed, :attended ]).sum(:seats)

    {
      total_capacity: event.max_capacity,
      seats_sold: confirmed_seats,
      seats_available: event.max_capacity - confirmed_seats,
      occupancy_rate: event.max_capacity > 0 ? (confirmed_seats.to_f / event.max_capacity * 100).round(1) : 0,
      is_sold_out: confirmed_seats >= event.max_capacity
    }
  end

  # Export event participations data
  def export_event_participations(event)
    event.participations.includes(:user).map do |participation|
      {
        id: participation.id,
        user_name: participation.user&.full_name,
        user_email: participation.user&.email,
        seats: participation.seats,
        total_price: (event.price_cents * participation.seats) / 100.0,
        status: participation.status.humanize,
        payment_id: participation.stripe_payment_id,
        booking_date: participation.created_at.strftime('%d/%m/%Y %H:%M'),
        user_phone: participation.user&.phone,
        special_requirements: participation.special_requirements
      }
    end
  end

  # Generate CSV for participations export
  def generate_participations_csv(data)
    return '' if data.empty?

    headers = data.first.keys
    CSV.generate(headers: true) do |csv|
      csv << headers.map(&:to_s).map(&:humanize)
      data.each { |row| csv << headers.map { |h| row[h] } }
    end
  end

  # Send notification to event participants
  def send_event_notification(event)
    participants = event.participations.where(status: [ :confirmed, :attended ])
                       .includes(:user)

    sent_count = 0
    errors = []

    participants.find_each do |participation|
      begin
        # Send email notification
        EventMailer.event_notification(participation).deliver_now
        sent_count += 1
      rescue StandardError => e
        errors << "Failed to send to #{participation.user&.email}: #{e.message}"
      end
    end

    if errors.empty?
      {
        success: true,
        message: "Notifications envoyées avec succès à #{sent_count} participants",
        sent_count: sent_count
      }
    else
      {
        success: false,
        error: "Erreurs lors de l'envoi: #{errors.join(', ')}",
        sent_count: sent_count
      }
    end
  end

  # Calculate booking conversion rate
  def calculate_booking_conversion_rate(event)
    total_users = User.count
    total_bookings = event.participations.where(status: [ :confirmed, :attended ]).count

    return 0 if total_users.zero?

    (total_bookings.to_f / total_users * 100).round(2)
  end

  # Calculate daily bookings pattern
  def calculate_daily_bookings(event)
    event.participations.where(status: [ :confirmed, :attended ])
         .group("DATE(created_at)")
         .count
         .transform_keys { |date| date.strftime('%d/%m') }
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

  # Strong parameters for event updates
  def event_params
    params.require(:event).permit(
      :title, :description, :venue_name, :venue_address,
      :event_date, :start_time, :max_capacity, :price_cents,
      :status, :movie_id
    )
  end
end
