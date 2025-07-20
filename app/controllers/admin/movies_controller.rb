class Admin::MoviesController < Admin::BaseController
  def bulk_validate
    movie_ids = params[:movie_ids] || []

    Movie.where(id: movie_ids).update_all(
      validation_status: :approved,
      validated_by_id: current_user.id,
      validated_at: Time.current
    )

    flash[:notice] = "#{movie_ids.count} films validés avec succès."

    respond_to do |format|
      format.html { redirect_back(fallback_location: admin_movies_path) }
      format.json { render json: { success: true, count: movie_ids.count } }
    end
  end

  def bulk_reject
    movie_ids = params[:movie_ids] || []

    Movie.where(id: movie_ids).update_all(
      validation_status: :rejected,
      validated_by_id: current_user.id,
      validated_at: Time.current
    )

    flash[:alert] = "#{movie_ids.count} films rejetés."

    respond_to do |format|
      format.html { redirect_back(fallback_location: admin_movies_path) }
      format.json { render json: { success: true, count: movie_ids.count } }
    end
  end
end
