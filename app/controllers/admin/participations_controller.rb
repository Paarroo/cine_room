class Admin::ParticipationsController < Admin::ApplicationController
  include ParticipationManagement
  before_action :set_participation, only: [:show, :update]

  # GET /admin/participations
  def index
    @participations_query = Participation.includes(:user, :event, event: :movie)

    # Status filter
    @participations_query = @participations_query.where(status: params[:status]) if params[:status].present?

    # Event filter
    @participations_query = @participations_query.joins(:event).where(events: { id: params[:event_id] }) if params[:event_id].present?

    # User search
    if params[:user_search].present?
      @participations_query = @participations_query.joins(:user)
                                                  .where("users.first_name ILIKE ? OR users.last_name ILIKE ? OR users.email ILIKE ?",
                                                         "%#{params[:user_search]}%", "%#{params[:user_search]}%", "%#{params[:user_search]}%")
    end

    # Date range filter
    case params[:date_filter]
    when "today"
      @participations_query = @participations_query.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day)
    when "week"
      @participations_query = @participations_query.where(created_at: 1.week.ago..Time.current)
    when "month"
      @participations_query = @participations_query.where(created_at: 1.month.ago..Time.current)
    end

    @participations = @participations_query.order(created_at: :desc).limit(100).to_a

    # Calculate statistics
    @stats = calculate_participation_stats

    # Get filter options for dropdowns
    @events_options = Event.joins(:participations).distinct.pluck(:title, :id)
    @status_options = Participation.statuses.keys
  end

  # GET /admin/participations/:id
  def show
    @event = @participation.event
    @user = @participation.user
    @movie = @event.movie
    @total_price = calculate_participation_total(@participation)
  end

  # PATCH /admin/participations/:id
  def update
    case params[:status]
    when 'confirmed'
      confirm_participation_action
    when 'cancelled'
      cancel_participation_action
    when 'pending'
      set_pending_participation_action
    else
      # Regular participation update
      update_participation_attributes
    end
  end

  # PATCH /admin/participations/bulk_confirm
  def bulk_confirm
    participation_ids = params[:participation_ids] || []

    if participation_ids.any?
      result = bulk_confirm_participations(participation_ids)

      respond_to do |format|
        format.json do
          render json: {
            status: 'success',
            message: "#{result[:count]} participations confirmed successfully",
            confirmed_count: result[:count]
          }
        end
        format.html do
          redirect_to admin_participations_path,
                     notice: "#{result[:count]} participations confirmed successfully"
        end
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', message: 'No participations selected' } }
        format.html { redirect_to admin_participations_path, alert: 'No participations selected' }
      end
    end
  rescue StandardError => e
    Rails.logger.error "Bulk confirm error: #{e.message}"
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_participations_path, alert: 'Error confirming participations' }
    end
  end

  # PATCH /admin/participations/bulk_cancel
  def bulk_cancel
    participation_ids = params[:participation_ids] || []

    if participation_ids.any?
      result = bulk_cancel_participations(participation_ids)

      respond_to do |format|
        format.json do
          render json: {
            status: 'success',
            message: "#{result[:count]} participations cancelled successfully",
            cancelled_count: result[:count]
          }
        end
        format.html do
          redirect_to admin_participations_path,
                     notice: "#{result[:count]} participations cancelled successfully"
        end
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', message: 'No participations selected' } }
        format.html { redirect_to admin_participations_path, alert: 'No participations selected' }
      end
    end
  rescue StandardError => e
    Rails.logger.error "Bulk cancel error: #{e.message}"
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_participations_path, alert: 'Error cancelling participations' }
    end
  end
