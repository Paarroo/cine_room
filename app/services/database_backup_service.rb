class DatabaseBackupService
  # Backup directory configuration
  BACKUP_DIR = Rails.root.join('storage', 'backups')

  def initialize
    ensure_backup_directory_exists
  end

  # Perform real database backup using pg_dump
  def perform_backup
    # Generate backup filename with timestamp
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    filename = "cineroom_backup_#{timestamp}.sql"
    backup_path = BACKUP_DIR.join(filename)

    Rails.logger.info "Starting database backup: #{filename}"

    # Get database configuration
    db_config = database_configuration
    
    # Build and execute pg_dump command
    pg_dump_cmd = build_pg_dump_command(db_config.merge(output_file: backup_path))
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
      cleanup_failed_backup(backup_path)
      
      {
        success: false,
        error: 'Database backup failed. Please check logs for details.'
      }
    end
  rescue StandardError => e
    Rails.logger.error "Database backup error: #{e.message}"
    cleanup_failed_backup(backup_path)

    {
      success: false,
      error: "Backup failed: #{e.message}"
    }
  end

  # List all available backups with metadata
  def list_backups
    backup_files = Dir.glob(BACKUP_DIR.join('cineroom_backup_*.sql'))
                     .map { |file| backup_file_info(file) }
                     .sort_by { |info| info[:created_at] }
                     .reverse

    {
      backups: backup_files,
      total_count: backup_files.length,
      total_size: backup_files.sum { |info| info[:size_bytes] }
    }
  end

  # Delete a specific backup file
  def delete_backup(filename)
    backup_path = BACKUP_DIR.join(filename)
    
    unless File.exist?(backup_path)
      return { success: false, error: 'Backup file not found' }
    end

    File.delete(backup_path)
    Rails.logger.info "Deleted backup file: #{filename}"
    
    { success: true, message: "Backup #{filename} deleted successfully" }
  rescue StandardError => e
    Rails.logger.error "Failed to delete backup #{filename}: #{e.message}"
    { success: false, error: "Failed to delete backup: #{e.message}" }
  end

  private

  def ensure_backup_directory_exists
    FileUtils.mkdir_p(BACKUP_DIR) unless Dir.exist?(BACKUP_DIR)
  end

  def database_configuration
    db_config = ActiveRecord::Base.connection_config
    {
      database_name: db_config[:database],
      username: db_config[:username],
      password: db_config[:password],
      host: db_config[:host] || 'localhost',
      port: db_config[:port] || 5432
    }
  end

  # Build pg_dump command with proper parameters and security
  def build_pg_dump_command(config)
    cmd_parts = []

    # Set password environment variable if provided
    cmd_parts << "PGPASSWORD='#{config[:password]}'" if config[:password].present?

    # Build pg_dump command with security options
    cmd_parts << "pg_dump"
    cmd_parts << "--verbose"
    cmd_parts << "--clean"
    cmd_parts << "--no-owner"
    cmd_parts << "--no-privileges"
    cmd_parts << "--format=plain"
    cmd_parts << "--host='#{config[:host]}'" if config[:host].present?
    cmd_parts << "--port=#{config[:port]}" if config[:port].present?
    cmd_parts << "--username='#{config[:username]}'" if config[:username].present?
    cmd_parts << "--dbname='#{config[:database_name]}'"
    cmd_parts << "--file='#{config[:output_file]}'"

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

  def cleanup_failed_backup(backup_path)
    File.delete(backup_path) if backup_path && File.exist?(backup_path)
  end

  # Format file size in human readable format
  def format_file_size(size_in_bytes)
    return '0 B' if size_in_bytes.zero?

    units = ['B', 'KB', 'MB', 'GB']
    base = 1024.0
    exp = (Math.log(size_in_bytes) / Math.log(base)).floor
    exp = [exp, units.length - 1].min

    formatted_size = (size_in_bytes / (base ** exp)).round(2)
    "#{formatted_size} #{units[exp]}"
  end

  # Get backup file information
  def backup_file_info(file_path)
    file_stat = File.stat(file_path)
    filename = File.basename(file_path)
    
    # Extract timestamp from filename
    timestamp_match = filename.match(/cineroom_backup_(\d{8}_\d{6})\.sql/)
    timestamp = timestamp_match ? timestamp_match[1] : 'unknown'

    {
      filename: filename,
      path: file_path,
      size: format_file_size(file_stat.size),
      size_bytes: file_stat.size,
      created_at: file_stat.mtime,
      timestamp: timestamp,
      readable_date: file_stat.mtime.strftime('%d/%m/%Y %H:%M:%S')
    }
  end
end