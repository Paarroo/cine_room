class Admin::ParticipationsController < Admin::ApplicationController
  include ParticipationsManagement
  before_action :set_participation, only: [ :show, :update ]

  # GET /admin/participations - mirrors ActiveAdmin index with scopes and filters
  def index
    # Apply scope filter (all/pending/confirmed/cancelled) - mirrors ActiveAdmin scopes
    scope = params[:scope] || 'all'
    @participations = participation_scopes[scope.to_sym] || participation_scopes[:all]

    # Apply additional filters using concern method
    @participations = filter_participations(params)

    # Limit results for performance
    @participations = @participations.limit(100)

    # Format data for display - mirrors ActiveAdmin columns
    @formatted_participations = @participations.map { |p| format_participation_data(p) }

    # Get statistics for dashboard - mirrors ActiveAdmin counters
    @stats = calculate_participation_statistics

    # Get revenue data for admin overview
    @revenue_data = calculate_participation_revenue

    # Get collections for filter dropdowns - mirrors ActiveAdmin form collections
    @filter_collections = get_participation_form_collections
    @filter_collections[:scopes] = participation_scopes.keys.map(&:to_s)

    # Export data if requested
    if params[:format] == 'csv'
      @export_data = export_participation_data(@participations)
      respond_to do |format|
        format.csv { send_csv_data(@export_data) }
      end
      return
    end
  end

  # GET /admin/participations/:id - mirrors ActiveAdmin show page
  def show
    # Format participation data using concern method - mirrors ActiveAdmin attributes_table
    @participation_data = format_participation_data(@participation)

    # Get related objects for display
    @user = @participation.user
    @event = @participation.event
    @movie = @event&.movie

    # Calculate additional metrics for this participation
    @total_price = @participation_data[:total_price]
    @formatted_total_price = @participation_data[:formatted_total_price]

    # Check if participation can be modified
    @can_modify = can_modify_participation?(@participation)
  end

  # PATCH /admin/participations/:id - handles status updates
  def update
    case params[:status]
    when 'confirmed'
      confirm_participation_action
    when 'cancelled'
      cancel_participation_action
    when 'pending'
      set_pending_participation_action
    else
      # Regular participation update with validation
      update_participation_attributes
    end
  end

  # PATCH /admin/participations/bulk_confirm - mirrors ActiveAdmin batch_action
  def bulk_confirm
    participation_ids = params[:participation_ids] || params[:ids] || []

    if participation_ids.any?
      # Use concern method - mirrors ActiveAdmin batch_action logic
      result = bulk_confirm_participations(participation_ids)

      respond_to do |format|
        format.json do
          render json: {
            status: result[:success] ? 'success' : 'error',
            message: result[:message],
            count: result[:count]
          }
        end
        format.html do
          if result[:success]
            redirect_to admin_participations_path, notice: result[:message]
          else
            redirect_to admin_participations_path, alert: result[:error]
          end
        end
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', message: 'No participations selected' } }
        format.html { redirect_to admin_participations_path, alert: 'No participations selected' }
      end
    end
  end

  # PATCH /admin/participations/bulk_cancel - mirrors ActiveAdmin batch_action
  def bulk_cancel
    participation_ids = params[:participation_ids] || params[:ids] || []

    if participation_ids.any?
      # Use concern method - mirrors ActiveAdmin batch_action logic
      result = bulk_cancel_participations(participation_ids)

      respond_to do |format|
        format.json do
          render json: {
            status: result[:success] ? 'success' : 'error',
            message: result[:message],
            count: result[:count]
          }
        end
        format.html do
          if result[:success]
            redirect_to admin_participations_path, notice: result[:message]
          else
            redirect_to admin_participations_path, alert: result[:error]
          end
        end
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', message: 'No participations selected' } }
        format.html { redirect_to admin_participations_path, alert: 'No participations selected' }
      end
    end
  end

  # GET /admin/participations/export - export functionality
  def export
    @participations = filter_participations(params)
    @export_data = export_participation_data(@participations)

    respond_to do |format|
      format.csv { send_csv_data(@export_data) }
      format.json { render json: { data: @export_data, count: @export_data.length } }
    end
  end

  private

  # Find participation by ID with error handling
  def set_participation
    @participation = Participation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { error: 'Participation not found' }, status: :not_found }
      format.html { redirect_to admin_participations_path, alert: 'Participation not found' }
    end
  end

  # Confirm single participation - uses concern method
  def confirm_participation_action
    result = update_participation_status(@participation, 'confirmed')

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

  # Cancel single participation - uses concern method
  def cancel_participation_action
    result = update_participation_status(@participation, 'cancelled')

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

  # Set participation to pending - uses concern method
  def set_pending_participation_action
    result = update_participation_status(@participation, 'pending')

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

  # Update participation with custom attributes - includes validation
  def update_participation_attributes
    # Validate data before update
    validation_result = validate_participation_data(participation_params)

    unless validation_result[:valid]
      respond_to do |format|
        format.json { render json: { status: 'error', errors: validation_result[:errors] } }
        format.html { redirect_to admin_participation_path(@participation), alert: validation_result[:errors].join(', ') }
      end
      return
    end

    if @participation.update(participation_params)
      respond_to do |format|
        format.json { render json: { status: 'success', message: 'Participation updated successfully' } }
        format.html { redirect_to admin_participation_path(@participation), notice: 'Participation updated successfully' }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @participation.errors.full_messages } }
        format.html { render :show, alert: @participation.errors.full_messages.join(', ') }
      end
    end
  end

  # Check if participation can be modified based on event status and date
  def can_modify_participation?(participation)
    return false unless participation
    return false if participation.event&.completed? || participation.event&.cancelled?
    return false if participation.event&.event_date && participation.event.event_date < Date.current

    true
  end

  # Send CSV data as download
  def send_csv_data(export_data)
    csv_content = generate_csv_content(export_data)
    filename = "participations_export_#{Date.current.strftime('%Y%m%d')}.csv"

    send_data csv_content,
              filename: filename,
              type: 'text/csv',
              disposition: 'attachment'
  end

  # Generate CSV content from export data
  def generate_csv_content(export_data)
    return '' if export_data.empty?

    require 'csv'

    CSV.generate(headers: true) do |csv|
      # Add headers
      csv << export_data.first.keys.map(&:to_s).map(&:humanize)

      # Add data rows
      export_data.each do |row|
        csv << row.values
      end
    end
  end

  # Strong parameters for participation updates - mirrors ActiveAdmin permit_params
  def participation_params
    params.require(:participation).permit(:user_id, :event_id, :status, :seats, :stripe_payment_id)
  end
end
