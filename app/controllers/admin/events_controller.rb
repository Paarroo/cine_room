class Admin::EventsController < Admin::BaseController
  def toggle_status
    @event = Event.find(params[:id])

    new_status = case @event.status
    when 'upcoming' then 'completed'
    when 'completed' then 'upcoming'
    when 'sold_out' then 'upcoming'
    else 'upcoming'
    end

    if @event.update(status: new_status)
      flash[:notice] = "Statut de l'événement mis à jour: #{new_status.humanize}"
    else
      flash[:alert] = "Erreur lors de la mise à jour du statut."
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: admin_events_path) }
      format.json { render json: { success: true, new_status: new_status } }
    end
  end
end
