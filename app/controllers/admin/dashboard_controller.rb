class Admin::DashboardController < Admin::ApplicationController
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::DateHelper

  # Backup directory configuration
  BACKUP_DIR = Rails.root.join('storage', 'backups')
  MAINTENANCE_FILE = Rails.root.join('tmp', 'maintenance.txt')

  # Main dashboard page with all metrics and data
  def index
    @metrics = calculate_metrics
    @revenue_chart_data = revenue_chart_data
    @events_chart_data = events_status_chart_data
    @pending_movies = Movie.where(validation_status: :pending).limit(5)
    @recent_activities = recent_activities
    @quick_stats = quick_stats
  end

  # AJAX endpoint for real-time dashboard refresh
  def refresh
    respond_to do |format|
      format.json do
        render json: {
          metrics: calculate_metrics,
          charts: {
            revenue: revenue_chart_data,
            events: events_status_chart_data
          },
          activities: recent_activities,
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

  # Export data functionality for various entity types
  def export_data
    data_type = params[:type] || 'users'

    respond_to do |format|
      format.json do
        case data_type
        when 'users'
          data = export_users_data
        when 'events'
          data = export_events_data
        when 'movies'
          data = export_movies_data
        when 'participations'
          data = export_participations_data
        else
          data = { error: 'Type non supporté' }
        end

        render json: {
          success: true,
          data: data,
          filename: "#{data_type}_export_#{Date.current.strftime('%Y%m%d')}.csv"
        }
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { error: e.message }, status: 500 }
    end
  end

  # Real database backup functionality with pg_dump
  def backup_database
    respond_to do |format|
      format.json do
        backup_result = perform_real_backup

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

  # Toggle maintenance mode functionality
  def toggle_maintenance_mode
    respond_to do |format|
      format.json do
        maintenance_result = toggle_maintenance

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

  # Calculate key business metrics for dashboard display
  def calculate_metrics
    {
      total_revenue: calculate_total_revenue,
      upcoming_events: Event.where(status: :upcoming).count,
      total_users: User.count,
      satisfaction: (Review.average(:rating) || 0).round(1)
    }
  end

  # Generate revenue chart data for the last 30 days
  def revenue_chart_data
    (30.days.ago.to_date..Date.current).map do |date|
      revenue = calculate_daily_revenue(date)
      {
        date: date.strftime("%d/%m"),
        revenue: revenue,
        formatted_revenue: number_to_currency(revenue)
      }
    end
  end

  # Calculate revenue for a specific date
  def calculate_daily_revenue(date)
    total_cents = Participation.includes(:event)
                              .where(status: :confirmed)
                              .where.not(stripe_payment_id: [nil, ''])
                              .where(created_at: date.beginning_of_day..date.end_of_day)
                              .sum { |p| (p.event.price_cents || 0) * p.seats }
    
    total_cents / 100.0
  end

  # Generate events status distribution data for charts
  def events_status_chart_data
    Event.group(:status).count.map do |status, count|
      total = Event.count
      {
        status: status.humanize,
        count: count,
        percentage: total.zero? ? 0 : ((count.to_f / total) * 100).round(1)
      }
    end
  end

  # Aggregate recent activities from participations and movies
  def recent_activities
    activities = []

    # Recent participations
    Participation.includes(:user, :event)
                 .order(created_at: :desc)
                 .limit(3)
                 .each do |participation|
      activities << {
        type: 'participation',
        title: 'Nouvelle réservation',
        description: "#{participation.user&.full_name} • #{participation.event&.title}",
        time_ago: time_ago_in_words(participation.created_at),
        icon: 'ticket-alt',
        color: 'primary'
      }
    end

    # Recent movies
    Movie.includes(:user)
         .order(created_at: :desc)
         .limit(2)
         .each do |movie|
      activities << {
        type: 'movie',
        title: 'Nouveau film ajouté',
        description: "\"#{movie.title}\" par #{movie.user&.full_name}",
        time_ago: time_ago_in_words(movie.created_at),
        icon: 'film',
        color: 'blue-400'
      }
    end

    activities.sort_by { |a| a[:time_ago] }.first(5)
  end

  # Quick statistics for action cards
  def quick_stats
    {
      pending_movies: Movie.where(validation_status: :pending).count,
      upcoming_events: Event.where(status: :upcoming).count,
      total_users: User.count,
      pending_participations: Participation.where(status: :pending).count
    }
  end

  # Calculate total revenue from confirmed participations
  def calculate_total_revenue
    # Use includes instead of joins for better performance and to avoid potential issues
    total_cents = Participation.includes(:event)
                              .where(status: :confirmed)
                              .where.not(stripe_payment_id: [nil, ''])
                              .sum { |p| (p.event.price_cents || 0) * p.seats }
    
    total_cents / 100.0
  end

  # Helper method for confirmed participations with event joins
  def confirmed_participations
    Participation.where(status: :confirmed).joins(:event)
  end

  # Export users data to CSV format
  def export_users_data
    User.select(:id, :email, :first_name, :last_name, :role, :created_at)
        .limit(1000)
        .map(&:attributes)
  end

  # Export events data to CSV format
  def export_events_data
    Event.includes(:movie)
         .select(:id, :title, :venue_name, :event_date, :max_capacity, :status)
         .limit(1000)
         .map(&:attributes)
  end

  # Export movies data to CSV format
  def export_movies_data
    Movie.includes(:user)
         .select(:id, :title, :director, :year, :validation_status, :created_at)
         .limit(1000)
         .map(&:attributes)
  end

  # Export participations data to CSV format
  def export_participations_data
    Participation.includes(:user, :event)
                 .select(:id, :user_id, :event_id, :seats, :status, :created_at)
                 .limit(1000)
                 .map(&:attributes)
  end

  # Real database backup implementation using pg_dump
  def perform_real_backup
    # Ensure backup directory exists
    FileUtils.mkdir_p(BACKUP_DIR) unless Dir.exist?(BACKUP_DIR)

    # Generate backup filename with timestamp
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    filename = "cineroom_backup_#{timestamp}.sql"
    backup_path = BACKUP_DIR.join(filename)

    # Database configuration from Rails
    db_config = ActiveRecord::Base.connection_config
    database_name = db_config[:database]
    username = db_config[:username]
    password = db_config[:password]
    host = db_config[:host] || 'localhost'
    port = db_config[:port] || 5432

    # Build pg_dump command with proper escaping
    pg_dump_cmd = build_pg_dump_command(
      database_name: database_name,
      username: username,
      password: password,
      host: host,
      port: port,
      output_file: backup_path
    )

    Rails.logger.info "Starting database backup: #{filename}"

    # Execute pg_dump command
    success = system(pg_dump_cmd)

    if success && File.exist?(backup_path)
      file_size = format_file_size(File.size(backup_path))

      Rails.logger.info "Database backup completed successfully: #{filename} (#{file_size})"

      # Clean old backups (keep only last 10)
      cleanup_old_backups

      {
        success: true,
        filename: filename,
        path: backup_path.to_s,
        size: file_size,
        timestamp: timestamp
      }
    else
      Rails.logger.error "Database backup failed for: #{filename}"

      # Clean up failed backup file if it exists
      File.delete(backup_path) if File.exist?(backup_path)

      {
        success: false,
        error: 'Database backup failed. Please check logs for details.'
      }
    end
  rescue StandardError => e
    Rails.logger.error "Database backup error: #{e.message}"

    # Clean up any partial backup file
    File.delete(backup_path) if backup_path && File.exist?(backup_path)

    {
      success: false,
      error: "Backup failed: #{e.message}"
    }
  end

  # Build pg_dump command with proper parameters
  def build_pg_dump_command(database_name:, username:, password:, host:, port:, output_file:)
    cmd_parts = []

    # Set password environment variable if provided
    if password.present?
      cmd_parts << "PGPASSWORD='#{password}'"
    end

    # Build pg_dump command
    cmd_parts << "pg_dump"
    cmd_parts << "--verbose"
    cmd_parts << "--clean"
    cmd_parts << "--no-owner"
    cmd_parts << "--no-privileges"
    cmd_parts << "--format=plain"
    cmd_parts << "--host='#{host}'" if host.present?
    cmd_parts << "--port=#{port}" if port.present?
    cmd_parts << "--username='#{username}'" if username.present?
    cmd_parts << "--dbname='#{database_name}'"
    cmd_parts << "--file='#{output_file}'"

    cmd_parts.join(' ')
  end

  # Clean up old backup files (keep only last 10)
  def cleanup_old_backups
    backup_files = Dir.glob(BACKUP_DIR.join('cineroom_backup_*.sql'))
                     .sort_by { |f| File.mtime(f) }
                     .reverse

    # Remove files beyond the 10 most recent
    files_to_remove = backup_files[10..-1] || []

    files_to_remove.each do |file|
      File.delete(file)
      Rails.logger.info "Cleaned up old backup: #{File.basename(file)}"
    rescue StandardError => e
      Rails.logger.warn "Failed to cleanup backup file #{file}: #{e.message}"
    end
  end

  # Format file size in human readable format
  def format_file_size(size_in_bytes)
    return '0 B' if size_in_bytes.zero?

    units = [ 'B', 'KB', 'MB', 'GB' ]
    base = 1024.0
    exp = (Math.log(size_in_bytes) / Math.log(base)).floor
    exp = [ exp, units.length - 1 ].min

    formatted_size = (size_in_bytes / (base ** exp)).round(2)
    "#{formatted_size} #{units[exp]}"
  end

  # Toggle maintenance mode by creating/removing maintenance file
  def toggle_maintenance
    if maintenance_mode_active?
      # Disable maintenance mode
      File.delete(MAINTENANCE_FILE) if File.exist?(MAINTENANCE_FILE)

      Rails.logger.info "Maintenance mode disabled by admin: #{current_user.email}"

      {
        success: true,
        message: 'Maintenance mode disabled successfully',
        active: false,
        timestamp: Time.current.iso8601
      }
    else
      # Enable maintenance mode
      maintenance_info = {
        enabled_at: Time.current.iso8601,
        enabled_by: current_user.email,
        reason: 'Maintenance mode activated from admin dashboard'
      }

      File.write(MAINTENANCE_FILE, maintenance_info.to_json)

      Rails.logger.info "Maintenance mode enabled by admin: #{current_user.email}"

      {
        success: true,
        message: 'Maintenance mode enabled successfully',
        active: true,
        timestamp: Time.current.iso8601
      }
    end
  rescue StandardError => e
    Rails.logger.error "Maintenance mode toggle error: #{e.message}"

    {
      success: false,
      error: "Failed to toggle maintenance mode: #{e.message}"
    }
  end

  # Check if maintenance mode is currently active
  def maintenance_mode_active?
    File.exist?(MAINTENANCE_FILE)
  end
end
