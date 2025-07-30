class Admin::ParticipationsController < Admin::ApplicationController
  include ParticipationsManagement

  before_action :set_participation, only: [:show, :update, :confirm, :cancel, :mark_attended, :check_in, :refund, :destroy]

  def index
    @participations_query = Participation.includes(:user, :event, event: :movie)
    @participations = filter_participations(params).limit(50).to_a

    view_service = ParticipationViewService.new
    view_data = view_service.prepare_index_data(@participations, params)
    
    @formatted_participations = view_data[:formatted_participations]
    @stats = view_data[:stats]
    @insights = view_data[:insights]
    @filter_options = view_data[:filter_options]
    @revenue_data = view_data[:revenue_data]
    @top_events = view_data[:top_events]
    @active_participants = view_data[:active_participants]
    @attendance_rates = view_data[:attendance_rates]
  end

  def show
    view_service = ParticipationViewService.new
    view_data = view_service.prepare_show_data(@participation)
    
    @participation_data = view_data[:participation_data]
    @user = view_data[:user]
    @event = view_data[:event]
    @movie = view_data[:movie]
    @can_modify = view_data[:can_modify]
    @participation_revenue = view_data[:participation_revenue]
    @related_participations = view_data[:related_participations]
    @booking_lead_time = view_data[:booking_lead_time]
  end

  def update
    if @participation.update(participation_params)
      log_participation_action('updated', @participation, participation_params.to_h)
      respond_to(&standard_success_response('Participation mise à jour'))
    else
      respond_to(&standard_error_response(@participation.errors))
    end
  end

  def confirm
    @participation.update!(status: :confirmed)
    log_participation_action('confirmed', @participation)
    respond_to(&standard_success_response('Participation confirmée'))
  rescue StandardError => e
    respond_to(&error_response(e, 'la confirmation'))
  end

  def cancel
    reason = params[:reason] || 'Cancelled by admin'
    @participation.update!(status: :cancelled)
    log_participation_action('cancelled', @participation, { reason: reason })
    respond_to(&standard_success_response('Participation annulée'))
  rescue StandardError => e
    respond_to(&error_response(e, 'l\'annulation'))
  end

  def bulk_confirm
    participation_ids = params[:participation_ids] || []
    return respond_to(&blank_selection_response) if participation_ids.blank?

    Rails.logger.info "🎫 Bulk confirm called with IDs: #{participation_ids.inspect}"
    
    service = ParticipationManagementService.new
    result = service.bulk_confirm_participations(participation_ids)
    Rails.logger.info "🎫 Bulk confirm result: #{result.inspect}"

    respond_to(&bulk_operation_response(result))
  rescue => e
    Rails.logger.error "🎫 Bulk confirm error: #{e.message}"
    respond_to(&bulk_error_response(e))
  end

  def bulk_cancel
    participation_ids = params[:participation_ids] || []
    return respond_to(&blank_selection_response) if participation_ids.blank?

    Rails.logger.info "🎫 Bulk cancel called with IDs: #{participation_ids.inspect}"
    
    service = ParticipationManagementService.new
    result = service.bulk_cancel_participations(participation_ids)
    Rails.logger.info "🎫 Bulk cancel result: #{result.inspect}"

    respond_to(&bulk_operation_response(result))
  rescue => e
    Rails.logger.error "🎫 Bulk cancel error: #{e.message}"
    respond_to(&bulk_error_response(e))
  end

  def export
    participations_scope = filter_participations(params)
    view_service = ParticipationViewService.new
    export_data = view_service.prepare_export_data(participations_scope)
    filename = "participations_export_#{Date.current.strftime('%Y%m%d')}.csv"

    respond_to do |format|
      format.json { render json: { success: true, data: export_data, filename: filename } }
      format.csv { send_data generate_csv(export_data), filename: filename }
    end
  rescue StandardError => e
    respond_to(&export_error_response(e))
  end

  def stats
    view_service = ParticipationViewService.new
    stats_data = view_service.prepare_stats_data
    respond_to(&stats_response(stats_data))
  end

  private

  def set_participation
    @participation = Participation.find(params[:id])
  end

  def participation_params
    params.require(:participation).permit(:status, :seats, :stripe_payment_id)
  end

  def log_participation_action(action, participation, details = {})
    participation_info = participation ? "participation_id:#{participation.id}" : 'multiple_participations'
    Rails.logger.info "Admin Participation Management: #{current_user.email} #{action} #{participation_info} - #{details}"
  end

  def generate_csv(data)
    return '' if data.empty?
    headers = data.first.keys
    CSV.generate(headers: true) do |csv|
      csv << headers
      data.each { |row| csv << headers.map { |h| row[h] } }
    end
  end

  # Response helpers
  def standard_success_response(message)
    proc do |format|
      format.json { render json: { status: 'success', message: message } }
      format.html { redirect_to admin_participation_path(@participation), notice: "#{message} avec succès" }
    end
  end

  def standard_error_response(errors)
    proc do |format|
      format.json { render json: { status: 'error', errors: errors } }
      format.html { render :show, alert: 'Erreur lors de la mise à jour' }
    end
  end

  def error_response(error, action_name)
    proc do |format|
      format.json { render json: { status: 'error', message: error.message } }
      format.html { redirect_to admin_participation_path(@participation), alert: "Erreur lors de #{action_name}" }
    end
  end

  def blank_selection_response
    proc do |format|
      format.json { render json: { status: 'error', message: 'Aucune participation sélectionnée' }, status: 422 }
      format.html { redirect_to admin_participations_path, alert: 'Aucune participation sélectionnée' }
    end
  end

  def bulk_operation_response(result)
    proc do |format|
      if result[:success]
        format.json { render json: { status: 'success', message: result[:message] } }
        format.html { redirect_to admin_participations_path, notice: result[:message] }
      else
        format.json { render json: { status: 'error', message: result[:error] || result[:message] }, status: 422 }
        format.html { redirect_to admin_participations_path, alert: result[:error] || result[:message] }
      end
    end
  end

  def bulk_error_response(error)
    proc do |format|
      format.json { render json: { status: 'error', message: error.message }, status: 500 }
      format.html { redirect_to admin_participations_path, alert: error.message }
    end
  end

  def export_error_response(error)
    proc do |format|
      format.json { render json: { status: 'error', message: error.message } }
      format.html { redirect_to admin_participations_path, alert: 'Erreur lors de l\'export' }
    end
  end

  def stats_response(data)
    proc do |format|
      format.json { render json: data }
    end
  end
end