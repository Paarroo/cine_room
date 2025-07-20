class Admin::ParticipationsController < Admin::BaseController
  def bulk_confirm
    participation_ids = params[:participation_ids] || []

    Participation.where(id: participation_ids).update_all(status: :confirmed)

    flash[:notice] = "#{participation_ids.count} réservations confirmées."

    respond_to do |format|
      format.html { redirect_back(fallback_location: admin_participations_path) }
      format.json { render json: { success: true, count: participation_ids.count } }
    end
  end

  def bulk_cancel
    participation_ids = params[:participation_ids] || []

    Participation.where(id: participation_ids).update_all(status: :cancelled)

    flash[:alert] = "#{participation_ids.count} réservations annulées."

    respond_to do |format|
      format.html { redirect_back(fallback_location: admin_participations_path) }
      format.json { render json: { success: true, count: participation_ids.count } }
    end
  end
end
