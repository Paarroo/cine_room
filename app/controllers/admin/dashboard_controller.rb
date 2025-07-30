class Admin::DashboardController < Admin::ApplicationController
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::DateHelper


  def index
    @analytics_service = DashboardAnalyticsService.new
    @activity_service = ActivityAggregationService.new(5)
    
    @metrics = @analytics_service.calculate_metrics
    @pending_movies = Movie.where(validation_status: :pending).limit(5)
    @recent_activities = @activity_service.recent_activities
    @quick_stats = @analytics_service.quick_stats
  end

  def refresh
    analytics_service = DashboardAnalyticsService.new
    activity_service = ActivityAggregationService.new(5)
    
    respond_to do |format|
      format.json do
        render json: {
          metrics: analytics_service.calculate_metrics,
          activities: activity_service.recent_activities,
          status: 'success'
        }
      end
      format.html { redirect_to admin_dashboard_index_path }
    end
  rescue StandardError => e
    Rails.logger.error "Dashboard refresh error: #{e.message}"
    respond_to do |format|
      format.json { render json: { error: e.message }, status: 500 }
      format.html { redirect_to admin_dashboard_index_path, alert: "Erreur de rafraîchissement" }
    end
  end


  def backup_database
    backup_service = DatabaseBackupService.new
    
    respond_to do |format|
      format.json do
        backup_result = backup_service.perform_backup

        if backup_result[:success]
          render json: {
            success: true,
            message: 'Database backup completed successfully',
            backup_file: backup_result[:filename],
            backup_path: backup_result[:path],
            file_size: backup_result[:size]
          }
        else
          render json: { error: backup_result[:error] }, status: 500
        end
      end
    end
  rescue StandardError => e
    Rails.logger.error "Database backup error: #{e.message}"
    respond_to do |format|
      format.json { render json: { error: e.message }, status: 500 }
    end
  end

  def toggle_maintenance_mode
    maintenance_service = MaintenanceService.new(current_user: current_user)
    
    respond_to do |format|
      format.json do
        maintenance_result = maintenance_service.toggle_maintenance_mode

        if maintenance_result[:success]
          render json: {
            success: true,
            message: maintenance_result[:message],
            maintenance_active: maintenance_result[:active],
            timestamp: maintenance_result[:timestamp]
          }
        else
          render json: { error: maintenance_result[:error] }, status: 500
        end
      end
    end
  rescue StandardError => e
    Rails.logger.error "Maintenance mode toggle error: #{e.message}"
    respond_to do |format|
      format.json { render json: { error: e.message }, status: 500 }
    end
  end

  private



end
