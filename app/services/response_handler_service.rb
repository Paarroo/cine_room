class ResponseHandlerService
  def self.handle_bulk_operation_response(result, success_redirect_path, error_redirect_path, operation_name)
    proc do |format|
      if result[:success]
        format.json { render json: { status: 'success', message: result[:message] } }
        format.html { redirect_to success_redirect_path, notice: result[:message] }
      else
        format.json { render json: { status: 'error', message: result[:error] }, status: 422 }
        format.html { redirect_to error_redirect_path, alert: result[:error] }
      end
    end
  end

  def self.handle_standard_update_response(model, success_path, error_view, log_action = nil, logger = nil, action_details = {})
    if model.save
      logger&.call(log_action, model, action_details) if log_action && logger
      
      proc do |format|
        format.json { render json: { status: 'success', message: "#{model.class.name} mis à jour" } }
        format.html { redirect_to success_path, notice: "#{model.class.name} mis à jour avec succès" }
      end
    else
      proc do |format|
        format.json { render json: { status: 'error', errors: model.errors } }
        format.html { render error_view, alert: 'Erreur lors de la mise à jour' }
      end
    end
  end

  def self.handle_action_response(action_name, model, success_path, log_action = nil, logger = nil)
    proc do |format|
      format.json { render json: { status: 'success', message: "#{model.class.name} #{action_name}" } }
      format.html { redirect_to success_path, notice: "#{model.class.name} #{action_name} avec succès" }
    end
  end

  def self.handle_error_response(error, error_path, action_name)
    proc do |format|
      format.json { render json: { status: 'error', message: error.message } }
      format.html { redirect_to error_path, alert: "Erreur lors de #{action_name}" }
    end
  end

  def self.handle_csv_export_response(export_data, filename)
    proc do |format|
      format.json do
        render json: {
          success: true,
          data: export_data,
          filename: filename
        }
      end
      format.csv do
        send_data generate_csv(export_data), filename: filename
      end
    end
  end

  def self.handle_json_stats_response(stats_data)
    proc do |format|
      format.json { render json: stats_data }
    end
  end

  def self.validate_bulk_ids(ids, redirect_path, error_message = 'Aucun élément sélectionné')
    return false if ids.blank?
    
    proc do |format|
      format.json { render json: { status: 'error', message: error_message }, status: 422 }
      format.html { redirect_to redirect_path, alert: error_message }
    end if ids.blank?
    
    true
  end

  private

  def self.generate_csv(data)
    return '' if data.empty?

    headers = data.first.keys
    CSV.generate(headers: true) do |csv|
      csv << headers
      data.each { |row| csv << headers.map { |h| row[h] } }
    end
  end
end