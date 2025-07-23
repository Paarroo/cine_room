class Admin::ParticipationsController < Admin::ApplicationController
  include ParticipationManagement
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
