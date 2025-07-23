class Admin::ParticipationsController < Admin::ApplicationController
  include ParticipationsManagement

  before_action :set_participation, only: [ :show, :update, :confirm, :cancel, :mark_attended, :check_in, :refund, :destroy ]

  def index
    @participations_query = Participation.includes(:user, :event, event: :movie)

    # Apply filters using concern method
    @participations = filter_participations(params).limit(50).to_a

    # Calculate stats using concern method
    @stats = calculate_participation_stats
    @insights = participation_insights

    # Get filter options for form
    @filter_options = get_participation_filter_options

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

  def mark_attended
    mark_as_attended_action(@participation)
    log_participation_action('marked_attended', @participation)

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Participation marquée comme présente' } }
      format.html { redirect_to admin_participation_path(@participation), notice: 'Participation marquée comme présente' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_participation_path(@participation), alert: 'Erreur lors du marquage' }
    end
  end

  def check_in
    if check_in_participant(@participation)
      log_participation_action('checked_in', @participation)

      respond_to do |format|
        format.json { render json: { status: 'success', message: 'Check-in effectué' } }
        format.html { redirect_to admin_participation_path(@participation), notice: 'Check-in effectué avec succès' }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', message: 'Check-in impossible' } }
        format.html { redirect_to admin_participation_path(@participation), alert: 'Check-in impossible' }
      end
    end
  end

  def refund
    if process_refund(@participation)
      log_participation_action('refunded', @participation, { amount: calculate_participation_revenue(@participation) })

      respond_to do |format|
        format.json { render json: { status: 'success', message: 'Remboursement effectué' } }
        format.html { redirect_to admin_participation_path(@participation), notice: 'Remboursement effectué avec succès' }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', message: 'Erreur lors du remboursement' } }
        format.html { redirect_to admin_participation_path(@participation), alert: 'Erreur lors du remboursement' }
      end
    end
  end

  def destroy
    event_title = @participation.event.title
    user_name = @participation.user.full_name
    revenue_lost = calculate_participation_revenue(@participation)

    @participation.destroy
    log_participation_action('deleted', @participation, {
      event: event_title,
      user: user_name,
      revenue_lost: revenue_lost
    })

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Participation supprimée' } }
      format.html { redirect_to admin_participations_path, notice: 'Participation supprimée avec succès' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_participations_path, alert: 'Erreur lors de la suppression' }
    end
  end

  # Bulk operations
  def bulk_confirm
    participation_ids = params[:participation_ids]
    return redirect_to admin_participations_path, alert: 'Aucune participation sélectionnée' if participation_ids.blank?

    bulk_confirm_participations(participation_ids)
    log_participation_action('bulk_confirmed', nil, { count: participation_ids.count, ids: participation_ids })

    respond_to do |format|
      format.json { render json: { status: 'success', message: "#{participation_ids.count} participations confirmées" } }
      format.html { redirect_to admin_participations_path, notice: "#{participation_ids.count} participations confirmées" }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_participations_path, alert: 'Erreur lors de la confirmation en masse' }
    end
  end

  def bulk_cancel
    participation_ids = params[:participation_ids]
    return redirect_to admin_participations_path, alert: 'Aucune participation sélectionnée' if participation_ids.blank?

    bulk_cancel_participations(participation_ids)
    log_participation_action('bulk_cancelled', nil, { count: participation_ids.count, ids: participation_ids })

    respond_to do |format|
      format.json { render json: { status: 'success', message: "#{participation_ids.count} participations annulées" } }
      format.html { redirect_to admin_participations_path, notice: "#{participation_ids.count} participations annulées" }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_participations_path, alert: 'Erreur lors de l\'annulation en masse' }
    end
  end

  def bulk_mark_attended
    participation_ids = params[:participation_ids]
    return redirect_to admin_participations_path, alert: 'Aucune participation sélectionnée' if participation_ids.blank?

    bulk_mark_attended(participation_ids)
    log_participation_action('bulk_marked_attended', nil, { count: participation_ids.count, ids: participation_ids })

    respond_to do |format|
      format.json { render json: { status: 'success', message: "#{participation_ids.count} participations marquées comme présentes" } }
      format.html { redirect_to admin_participations_path, notice: "#{participation_ids.count} participations marquées comme présentes" }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_participations_path, alert: 'Erreur lors du marquage en masse' }
    end
  end

  # Analytics and insights
  def analytics
    @comprehensive_stats = calculate_participation_stats
    @insights = participation_insights
    @top_events = top_events_by_participation(10)
    @active_participants = most_active_participants(10)
    @attendance_rates = calculate_attendance_rates

    # Revenue data for charts
    @revenue_by_month = revenue_by_period(:month)
    @revenue_by_week = revenue_by_period(:week)

    # Participation trends
    @participation_trends = (12.months.ago.to_date..Date.current).group_by(&:month).map do |month, dates|
      month_participations = Participation.where(created_at: dates.first.beginning_of_month..dates.first.end_of_month)
      {
        month: dates.first.strftime('%B %Y'),
        count: month_participations.count,
        confirmed: month_participations.where(status: :confirmed).count,
        revenue: month_participations.joins(:event)
                                   .where(status: [ :confirmed, :attended ])
                                   .sum('events.price_cents * participations.seats') / 100.0
      }
    end

    # Capacity utilization trends
    @capacity_trends = (6.months.ago.to_date..Date.current).group_by(&:month).map do |month, dates|
      month_events = Event.where(event_date: dates.first.beginning_of_month..dates.first.end_of_month)
      total_capacity = month_events.sum(:max_capacity)
      total_bookings = Participation.joins(:event)
                                   .where(events: { event_date: dates.first.beginning_of_month..dates.first.end_of_month })
                                   .where(status: [ :confirmed, :attended ])
                                   .sum(:seats)

      utilization = total_capacity.zero? ? 0 : ((total_bookings.to_f / total_capacity) * 100).round(1)

      {
        month: dates.first.strftime('%B'),
        utilization: utilization,
        capacity: total_capacity,
        bookings: total_bookings
      }
    end

    respond_to do |format|
      format.html
      format.json { render json: { stats: @comprehensive_stats, insights: @insights } }
    end
  end

  # Export functionality
  def export
    participations_scope = filter_participations(params)
    @export_data = export_participations_data(participations_scope)

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

  # Revenue analysis endpoint
  def revenue_analysis
    period = params[:period] || 'month'
    @revenue_data = revenue_by_period(period.to_sym)
    @revenue_stats = {
      total: @revenue_data.values.sum,
      average: @revenue_data.values.sum / [ @revenue_data.count, 1 ].max,
      trend: calculate_revenue_trend
    }

    respond_to do |format|
      format.json do
        render json: {
          revenue_data: @revenue_data,
          revenue_stats: @revenue_stats,
          period: period
        }
      end
    end
  end

  # Get statistics for dashboard widgets
  def stats
    respond_to do |format|
      format.json do
        render json: {
          stats: calculate_participation_stats,
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

  # Attendance tracking
  def attendance_report
    @events_today = Event.where(event_date: Date.current).includes(:participations, :movie)
    @attendance_summary = @events_today.map do |event|
      participations = event.participations.where(status: [ :confirmed, :attended ])
      {
        event: event,
        total_confirmed: participations.where(status: :confirmed).count,
        total_attended: participations.where(status: :attended).count,
        total_seats: participations.sum(:seats),
        capacity_used: event.max_capacity.zero? ? 0 : ((participations.sum(:seats).to_f / event.max_capacity) * 100).round(1)
      }
    end

    respond_to do |format|
      format.html
      format.json { render json: { events: @events_today, summary: @attendance_summary } }
    end
  end

  # Payment status report
  def payment_report
    @payment_stats = {
      total_participations: Participation.count,
      paid: Participation.where.not(stripe_payment_id: [ nil, '' ]).count,
      unpaid: Participation.where(stripe_payment_id: [ nil, '' ]).count,
      total_revenue: confirmed_participations.sum("events.price_cents * participations.seats") / 100.0,
      outstanding_amount: Participation.joins(:event)
                                      .where(stripe_payment_id: [ nil, '' ])
                                      .where(status: [ :confirmed, :pending ])
                                      .sum('events.price_cents * participations.seats') / 100.0
    }

    @unpaid_participations = Participation.includes(:user, :event)
                                         .where(stripe_payment_id: [ nil, '' ])
                                         .where(status: [ :confirmed, :pending ])
                                         .order(created_at: :desc)
                                         .limit(20)

    respond_to do |format|
      format.html
      format.json { render json: { stats: @payment_stats, unpaid: @unpaid_participations } }
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

    # FOR RGPD
    # AuditLog.create(
    #   admin_user: current_user,
    #   action: action,
    #   target_type: 'Participation',
    #   target_id: participation&.id,
    #   details: details,
    #   ip_address: request.remote_ip,
    #   user_agent: request.user_agent
    # )
  end
end
