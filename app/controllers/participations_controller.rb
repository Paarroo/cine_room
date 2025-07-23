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
