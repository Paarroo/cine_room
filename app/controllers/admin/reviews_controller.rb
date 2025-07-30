class Admin::ReviewsController < Admin::ApplicationController
  include ReviewsManagement

  before_action :set_review, only: [:show, :update, :approve, :reject, :flag, :destroy]

  def index
    @reviews_query = Review.includes(:user, :movie, :event)
    @reviews = filter_reviews(params).limit(50).to_a

    view_service = ReviewViewService.new
    view_data = view_service.prepare_index_data(@reviews)
    
    @stats = view_data[:stats]
    @insights = view_data[:insights]
    @filter_options = view_data[:filter_options]
    @top_movies = view_data[:top_movies]
    @active_reviewers = view_data[:active_reviewers]
  end

  def show
    view_service = ReviewViewService.new
    view_data = view_service.prepare_show_data(@review)
    
    @sentiment_analysis = view_data[:sentiment_analysis]
    @quality_score = view_data[:quality_score]
    @related_reviews = view_data[:related_reviews]
  end

  def update
    if @review.update(review_params)
      log_review_action('updated', @review, review_params.to_h)
      respond_to(&standard_success_response('Avis mis à jour'))
    else
      respond_to(&standard_error_response(@review.errors))
    end
  end

  def approve
    approve_review_action(@review)
    log_review_action('approved', @review)
    respond_to(&standard_success_response('Avis approuvé'))
  rescue StandardError => e
    respond_to(&error_response(e, 'l\'approbation'))
  end

  def reject
    reason = params[:reason] || 'Content violates community guidelines'
    reject_review_action(@review)
    log_review_action('rejected', @review, { reason: reason })
    respond_to(&standard_success_response('Avis rejeté'))
  rescue StandardError => e
    respond_to(&error_response(e, 'le rejet'))
  end

  def flag
    reason = params[:reason] || 'inappropriate_content'
    flag_review_action(@review, reason)
    log_review_action('flagged', @review, { reason: reason })
    respond_to(&flag_success_response(reason))
  rescue StandardError => e
    respond_to(&error_response(e, 'le signalement'))
  end

  def destroy
    movie_title = @review.movie.title
    user_name = @review.user.full_name
    @review.destroy
    log_review_action('deleted', @review, { movie: movie_title, user: user_name })
    respond_to(&destroy_success_response)
  rescue StandardError => e
    respond_to(&destroy_error_response(e))
  end

  def bulk_approve
    review_ids = params[:review_ids]
    return respond_to(&blank_selection_response) if review_ids.blank?

    service = ReviewModerationService.new
    result = service.bulk_approve_reviews(review_ids)
    log_review_action('bulk_approved', nil, { count: review_ids.count, ids: review_ids })
    respond_to(&bulk_operation_response(result))
  end

  def bulk_reject
    review_ids = params[:review_ids]
    return respond_to(&blank_selection_response) if review_ids.blank?

    service = ReviewModerationService.new
    result = service.bulk_reject_reviews(review_ids)
    log_review_action('bulk_rejected', nil, { count: review_ids.count, ids: review_ids })
    respond_to(&bulk_operation_response(result))
  end

  def bulk_delete
    review_ids = params[:review_ids]
    return respond_to(&blank_selection_response) if review_ids.blank?

    service = ReviewModerationService.new
    result = service.bulk_delete_reviews(review_ids)
    log_review_action('bulk_deleted', nil, { count: result[:count], ids: review_ids })
    respond_to(&bulk_operation_response(result))
  end

  def analytics
    view_service = ReviewViewService.new
    view_data = view_service.prepare_analytics_data
    
    @comprehensive_stats = view_data[:comprehensive_stats]
    @insights = view_data[:insights]
    @top_movies = view_data[:top_movies]
    @active_reviewers = view_data[:active_reviewers]
    @monthly_data = view_data[:monthly_data]
    @sentiment_trends = view_data[:sentiment_trends]

    respond_to do |format|
      format.html
      format.json { render json: { stats: @comprehensive_stats, insights: @insights } }
    end
  end

  def export
    reviews_scope = filter_reviews(params)
    view_service = ReviewViewService.new
    export_data = view_service.prepare_export_data(reviews_scope)
    filename = "reviews_export_#{Date.current.strftime('%Y%m%d')}.csv"

    respond_to do |format|
      format.json { render json: { success: true, data: export_data, filename: filename } }
      format.csv { send_data generate_csv(export_data), filename: filename }
    end
  rescue StandardError => e
    respond_to(&export_error_response(e))
  end

  def sentiment_analysis
    review_id = params[:id]
    review = Review.find(review_id)
    view_service = ReviewViewService.new
    analysis_data = view_service.analyze_single_review(review)

    respond_to do |format|
      format.json { render json: analysis_data }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { error: 'Review not found' }, status: 404 }
    end
  end

  def stats
    view_service = ReviewViewService.new
    stats_data = view_service.prepare_stats_data
    respond_to(&stats_response(stats_data))
  end

  def quality_report
    view_service = ReviewViewService.new
    report_data = view_service.prepare_quality_report_data
    @reviews_with_scores = report_data[:reviews_with_scores]
    @quality_distribution = report_data[:quality_distribution]

    respond_to do |format|
      format.html
      format.json { render json: { reviews: @reviews_with_scores, distribution: @quality_distribution } }
    end
  end

  private

  def set_review
    @review = Review.find(params[:id])
  end

  def review_params
    params.require(:review).permit(:rating, :comment, :status)
  end

  def log_review_action(action, review, details = {})
    review_info = review ? "review_id:#{review.id}" : 'multiple_reviews'
    Rails.logger.info "Admin Review Management: #{current_user.email} #{action} #{review_info} - #{details}"
  end

  def generate_csv(data)
    return '' if data.empty?
    headers = data.first.keys
    CSV.generate(headers: true) do |csv|
      csv << headers
      data.each { |row| csv << headers.map { |h| row[h] } }
    end
  end

  # Response helpers
  def standard_success_response(message)
    proc do |format|
      format.json { render json: { status: 'success', message: message } }
      format.html { redirect_to admin_review_path(@review), notice: "#{message} avec succès" }
    end
  end

  def standard_error_response(errors)
    proc do |format|
      format.json { render json: { status: 'error', errors: errors } }
      format.html { render :show, alert: 'Erreur lors de la mise à jour' }
    end
  end

  def error_response(error, action_name)
    proc do |format|
      format.json { render json: { status: 'error', message: error.message } }
      format.html { redirect_to admin_review_path(@review), alert: "Erreur lors de #{action_name}" }
    end
  end

  def flag_success_response(reason)
    proc do |format|
      format.json { render json: { status: 'success', message: 'Avis signalé' } }
      format.html { redirect_to admin_review_path(@review), notice: "Avis signalé pour: #{reason}" }
    end
  end

  def destroy_success_response
    proc do |format|
      format.json { render json: { status: 'success', message: 'Avis supprimé' } }
      format.html { redirect_to admin_reviews_path, notice: 'Avis supprimé avec succès' }
    end
  end

  def destroy_error_response(error)
    proc do |format|
      format.json { render json: { status: 'error', message: error.message } }
      format.html { redirect_to admin_reviews_path, alert: 'Erreur lors de la suppression' }
    end
  end

  def blank_selection_response
    proc do |format|
      format.json { render json: { status: 'error', message: 'Aucun avis sélectionné' }, status: 422 }
      format.html { redirect_to admin_reviews_path, alert: 'Aucun avis sélectionné' }
    end
  end

  def bulk_operation_response(result)
    proc do |format|
      if result[:success]
        format.json { render json: { status: 'success', message: result[:message] } }
        format.html { redirect_to admin_reviews_path, notice: result[:message] }
      else
        format.json { render json: { status: 'error', message: result[:error] } }
        format.html { redirect_to admin_reviews_path, alert: result[:error] }
      end
    end
  end

  def export_error_response(error)
    proc do |format|
      format.json { render json: { status: 'error', message: error.message } }
      format.html { redirect_to admin_reviews_path, alert: 'Erreur lors de l\'export' }
    end
  end

  def stats_response(data)
    proc do |format|
      format.json { render json: data }
    end
  end
end