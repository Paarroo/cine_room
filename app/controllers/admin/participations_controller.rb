class Admin::ParticipationsController < Admin::ApplicationController
  include ParticipationsManagement

  before_action :set_participation, only: [ :show, :update, :confirm, :cancel, :mark_attended, :check_in, :refund, :destroy ]

  def index
    @participations_query = Participation.includes(:user, :event, event: :movie)

    # Apply filters using concern method
    @participations = filter_participations(params).limit(50).to_a

      # FORMAT DATA for view consumption
      @formatted_participations = @participations.map do |participation|
        format_participation_data(participation)
      end

    # Calculate stats using concern method - FIX: use correct method name
    @stats = calculate_participation_statistics
    @insights = participation_insights
    @filter_options = get_participation_filter_options
    @revenue_data = calculate_participation_revenue

    @revenue_data = calculate_participation_revenue

    # Additional data for dashboard
    @top_events = top_events_by_participation(5)
    @active_participants = most_active_participants(5)
    @attendance_rates = calculate_attendance_rates
  end

  def show
    @participation_revenue = calculate_participation_revenue(@participation)
    @related_participations = Participation.joins(:event)
                                          .where(events: { id: @participation.event_id })
                                          .where.not(id: @participation.id)
                                          .includes(:user)
                                          .order(created_at: :desc)
                                          .limit(10)

    # Calculate lead time (days before event when booked)
    @booking_lead_time = if @participation.event.event_date
                          (@participation.event.event_date - @participation.created_at.to_date).to_i
    else
                          nil
    end
  end

  def update
    if @participation.update(participation_params)
      log_participation_action('updated', @participation, participation_params.to_h)

      respond_to do |format|
        format.json { render json: { status: 'success', message: 'Participation mise à jour' } }
        format.html { redirect_to admin_participation_path(@participation), notice: 'Participation mise à jour avec succès' }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @participation.errors } }
        format.html { render :show, alert: 'Erreur lors de la mise à jour' }
      end
    end
  end

  # Status management actions
  def confirm
    confirm_participation_action(@participation)
    log_participation_action('confirmed', @participation)

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Participation confirmée' } }
      format.html { redirect_to admin_participation_path(@participation), notice: 'Participation confirmée avec succès' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_participation_path(@participation), alert: 'Erreur lors de la confirmation' }
    end
  end

  def cancel
    reason = params[:reason] || 'Cancelled by admin'
    cancel_participation_action(@participation)
    log_participation_action('cancelled', @participation, { reason: reason })

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Participation annulée' } }
      format.html { redirect_to admin_participation_path(@participation), notice: 'Participation annulée' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_participation_path(@participation), alert: 'Erreur lors de l\'annulation' }
    end
  end

  # Bulk operations
  def bulk_confirm
    participation_ids = params[:participation_ids]
    return redirect_to admin_participations_path, alert: 'Aucune participation sélectionnée' if participation_ids.blank?

    result = bulk_confirm_participations(participation_ids)

    respond_to do |format|
      if result[:success]
        format.json { render json: { status: 'success', message: result[:message] } }
        format.html { redirect_to admin_participations_path, notice: result[:message] }
      else
        format.json { render json: { status: 'error', message: result[:error] } }
        format.html { redirect_to admin_participations_path, alert: result[:error] }
      end
    end
  end

  def bulk_cancel
    participation_ids = params[:participation_ids]
    return redirect_to admin_participations_path, alert: 'Aucune participation sélectionnée' if participation_ids.blank?

    result = bulk_cancel_participations(participation_ids)

    respond_to do |format|
      if result[:success]
        format.json { render json: { status: 'success', message: result[:message] } }
        format.html { redirect_to admin_participations_path, notice: result[:message] }
      else
        format.json { render json: { status: 'error', message: result[:error] } }
        format.html { redirect_to admin_participations_path, alert: result[:error] }
      end
    end
  end

  # Export functionality
  def export
    participations_scope = filter_participations(params)
    @export_data = export_participation_data(participations_scope)

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          data: @export_data,
          filename: "participations_export_#{Date.current.strftime('%Y%m%d')}.csv"
        }
      end
      format.csv do
        send_data generate_csv(@export_data),
                  filename: "participations_export_#{Date.current.strftime('%Y%m%d')}.csv"
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_participations_path, alert: 'Erreur lors de l\'export' }
    end
  end

  # Statistics endpoint
  def stats
    respond_to do |format|
      format.json do
        render json: {
          stats: calculate_participation_statistics,
          insights: participation_insights,
          pending_confirmations: Participation.where(status: :pending).count,
          todays_events: Event.where(event_date: Date.current).joins(:participations).distinct.count,
          revenue_today: Participation.joins(:event)
                                     .where(status: [ :confirmed, :attended ])
                                     .where(created_at: Date.current.beginning_of_day..Date.current.end_of_day)
                                     .sum('events.price_cents * participations.seats') / 100.0
        }
      end
    end
  end

  private

  def set_participation
    @participation = Participation.find(params[:id])
  end

  def participation_params
    params.require(:participation).permit(:status, :seats, :stripe_payment_id)
  end

  # Generate CSV from export data
  def generate_csv(data)
    return '' if data.empty?

    headers = data.first.keys
    CSV.generate(headers: true) do |csv|
      csv << headers
      data.each { |row| csv << headers.map { |h| row[h] } }
    end
  end

  # Helper method for confirmed participations with event joins
  def confirmed_participations
    Participation.where(status: [ :confirmed, :attended ]).joins(:event)
  end

  # Enhanced logging with admin context
  def log_participation_action(action, participation, details = {})
    participation_info = participation ? "participation_id:#{participation.id}" : 'multiple_participations'
    Rails.logger.info "Admin Participation Management: #{current_user.email} #{action} #{participation_info} - #{details}"
  end

  # Additional methods that might be missing from the concern
  def confirm_participation_action(participation)
    participation.update!(status: :confirmed)
  end

  def cancel_participation_action(participation)
    participation.update!(status: :cancelled)
  end

  def calculate_participation_revenue(participation)
    return 0 unless participation.event&.price_cents && participation.seats
    (participation.event.price_cents * participation.seats) / 100.0
  end

  def participation_insights
    {
      conversion_rate: calculate_conversion_rate,
      average_booking_time: calculate_average_booking_time,
      peak_booking_hours: calculate_peak_booking_hours
    }
  end

  def get_participation_filter_options
    {
      statuses: Participation.statuses.keys.map { |s| [ s.humanize, s ] },
      events: Event.joins(:participations).distinct.limit(20).pluck(:title, :id),
      venues: Event.joins(:participations).distinct.pluck(:venue_name).compact.uniq
    }
  end

  def top_events_by_participation(limit = 5)
    Event.joins(:participations)
         .where(participations: { status: [ :confirmed, :attended ] })
         .group('events.id')
         .order('COUNT(participations.id) DESC')
         .limit(limit)
         .includes(:movie)
  end

  def most_active_participants(limit = 5)
    User.joins(:participations)
        .where(participations: { status: [ :confirmed, :attended ] })
        .group('users.id')
        .order('COUNT(participations.id) DESC')
        .limit(limit)
  end

  def calculate_attendance_rates
    total_confirmed = Participation.where(status: [ :confirmed, :attended ]).count
    total_attended = Participation.where(status: :attended).count

    return 0 if total_confirmed.zero?

    (total_attended.to_f / total_confirmed * 100).round(1)
  end

  def calculate_conversion_rate
    total_users = User.count
    participants = User.joins(:participations).distinct.count

    return 0 if total_users.zero?

    (participants.to_f / total_users * 100).round(1)
  end

  def calculate_average_booking_time
    # Average time between user registration and first booking
    bookings_with_user_age = Participation.joins(:user)
                                         .where(status: [ :confirmed, :attended ])
                                         .where.not(users: { created_at: nil })

    return 0 if bookings_with_user_age.empty?

    total_days = bookings_with_user_age.sum do |p|
      (p.created_at.to_date - p.user.created_at.to_date).to_i
    end

    (total_days.to_f / bookings_with_user_age.count).round(1)
  end

  def calculate_peak_booking_hours
    Participation.where(status: [ :confirmed, :attended ])
                 .group("EXTRACT(hour FROM created_at)")
                 .count
                 .sort_by { |hour, count| -count }
                 .first(3)
                 .map { |hour, count| { hour: hour.to_i, count: count } }
  end
end
