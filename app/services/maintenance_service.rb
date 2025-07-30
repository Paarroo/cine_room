class MaintenanceService
  MAINTENANCE_FILE = Rails.root.join('tmp', 'maintenance.txt')

  def initialize(current_user: nil)
    @current_user = current_user
  end

  # Toggle maintenance mode on/off
  def toggle_maintenance_mode
    if active?
      disable_maintenance_mode
    else
      enable_maintenance_mode
    end
  end

  # Enable maintenance mode
  def enable_maintenance_mode(reason: nil)
    maintenance_info = {
      enabled_at: Time.current.iso8601,
      enabled_by: @current_user&.email || 'system',
      reason: reason || 'Maintenance mode activated'
    }

    File.write(MAINTENANCE_FILE, maintenance_info.to_json)
    log_maintenance_action('enabled')

    {
      success: true,
      message: 'Maintenance mode enabled successfully',
      active: true,
      timestamp: Time.current.iso8601,
      info: maintenance_info
    }
  rescue StandardError => e
    Rails.logger.error "Failed to enable maintenance mode: #{e.message}"
    
    {
      success: false,
      error: "Failed to enable maintenance mode: #{e.message}"
    }
  end

  # Disable maintenance mode
  def disable_maintenance_mode
    File.delete(MAINTENANCE_FILE) if File.exist?(MAINTENANCE_FILE)
    log_maintenance_action('disabled')

    {
      success: true,
      message: 'Maintenance mode disabled successfully',
      active: false,
      timestamp: Time.current.iso8601
    }
  rescue StandardError => e
    Rails.logger.error "Failed to disable maintenance mode: #{e.message}"
    
    {
      success: false,
      error: "Failed to disable maintenance mode: #{e.message}"
    }
  end

  # Check if maintenance mode is currently active
  def active?
    File.exist?(MAINTENANCE_FILE)
  end

  # Get maintenance mode status and information
  def status
    if active?
      maintenance_info = parse_maintenance_info
      
      {
        active: true,
        enabled_at: maintenance_info[:enabled_at],
        enabled_by: maintenance_info[:enabled_by],
        reason: maintenance_info[:reason],
        duration: calculate_maintenance_duration(maintenance_info[:enabled_at])
      }
    else
      {
        active: false,
        enabled_at: nil,
        enabled_by: nil,
        reason: nil,
        duration: nil
      }
    end
  end

  # Schedule maintenance mode for a specific time
  def schedule_maintenance(scheduled_at:, duration_minutes: 60, reason: 'Scheduled maintenance')
    # This would integrate with a job scheduler like Sidekiq
    # For now, we'll just store the schedule information
    
    schedule_info = {
      scheduled_at: scheduled_at.iso8601,
      duration_minutes: duration_minutes,
      reason: reason,
      scheduled_by: @current_user&.email || 'system',
      created_at: Time.current.iso8601
    }

    schedule_file = Rails.root.join('tmp', 'maintenance_schedule.json')
    File.write(schedule_file, schedule_info.to_json)

    Rails.logger.info "Maintenance scheduled for #{scheduled_at} by #{@current_user&.email}"

    {
      success: true,
      message: 'Maintenance scheduled successfully',
      schedule: schedule_info
    }
  rescue StandardError => e
    Rails.logger.error "Failed to schedule maintenance: #{e.message}"
    
    {
      success: false,
      error: "Failed to schedule maintenance: #{e.message}"
    }
  end

  # Get scheduled maintenance information
  def scheduled_maintenance
    schedule_file = Rails.root.join('tmp', 'maintenance_schedule.json')
    
    return { scheduled: false } unless File.exist?(schedule_file)

    schedule_info = JSON.parse(File.read(schedule_file), symbolize_names: true)
    scheduled_time = Time.parse(schedule_info[:scheduled_at])

    {
      scheduled: true,
      scheduled_at: scheduled_time,
      duration_minutes: schedule_info[:duration_minutes],
      reason: schedule_info[:reason],
      scheduled_by: schedule_info[:scheduled_by],
      time_until: time_until_maintenance(scheduled_time),
      is_past_due: scheduled_time < Time.current
    }
  rescue StandardError => e
    Rails.logger.error "Failed to read maintenance schedule: #{e.message}"
    { scheduled: false, error: e.message }
  end

  private

  def parse_maintenance_info
    return default_maintenance_info unless File.exist?(MAINTENANCE_FILE)

    JSON.parse(File.read(MAINTENANCE_FILE), symbolize_names: true)
  rescue JSON::ParserError => e
    Rails.logger.warn "Failed to parse maintenance file: #{e.message}"
    default_maintenance_info
  end

  def default_maintenance_info
    {
      enabled_at: File.mtime(MAINTENANCE_FILE).iso8601,
      enabled_by: 'unknown',
      reason: 'Maintenance mode active'
    }
  end

  def calculate_maintenance_duration(enabled_at_string)
    return nil unless enabled_at_string

    enabled_at = Time.parse(enabled_at_string)
    duration_seconds = (Time.current - enabled_at).to_i
    
    if duration_seconds < 60
      "#{duration_seconds} seconds"
    elsif duration_seconds < 3600
      "#{duration_seconds / 60} minutes"
    else
      hours = duration_seconds / 3600
      minutes = (duration_seconds % 3600) / 60
      "#{hours}h #{minutes}m"
    end
  rescue StandardError
    'Unknown duration'
  end

  def time_until_maintenance(scheduled_time)
    return nil if scheduled_time < Time.current

    time_diff = (scheduled_time - Time.current).to_i
    
    if time_diff < 60
      "#{time_diff} seconds"
    elsif time_diff < 3600
      "#{time_diff / 60} minutes"
    elsif time_diff < 86400
      hours = time_diff / 3600
      minutes = (time_diff % 3600) / 60
      "#{hours}h #{minutes}m"
    else
      days = time_diff / 86400
      hours = (time_diff % 86400) / 3600
      "#{days}d #{hours}h"
    end
  end

  def log_maintenance_action(action)
    user_email = @current_user&.email || 'system'
    Rails.logger.info "Maintenance mode #{action} by: #{user_email}"
  end
end