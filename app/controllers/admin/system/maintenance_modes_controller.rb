class Admin::System::MaintenanceModesController < Admin::ApplicationController
  
  def create
    Rails.logger.info "Maintenance mode activated by admin: #{current_user.email}"
    
    # Create maintenance mode file
    maintenance_file_path = Rails.root.join('tmp', 'maintenance.txt')
    File.write(maintenance_file_path, "Maintenance mode activated at #{Time.current} by #{current_user.email}")
    
    redirect_to admin_root_path, notice: 'Mode maintenance activé'
  rescue => e
    Rails.logger.error "Error activating maintenance mode: #{e.message}"
    redirect_to admin_root_path, alert: 'Erreur lors de l\'activation du mode maintenance'
  end

  def destroy
    Rails.logger.info "Maintenance mode deactivated by admin: #{current_user.email}"
    
    # Remove maintenance mode file
    maintenance_file_path = Rails.root.join('tmp', 'maintenance.txt')
    File.delete(maintenance_file_path) if File.exist?(maintenance_file_path)
    
    redirect_to admin_root_path, notice: 'Mode maintenance désactivé'
  rescue => e
    Rails.logger.error "Error deactivating maintenance mode: #{e.message}"
    redirect_to admin_root_path, alert: 'Erreur lors de la désactivation du mode maintenance'
  end
end