class Admin::ReviewsController < Admin::ApplicationController
  include ReviewsManagement

  before_action :set_review, only: [ :show, :update, :approve, :reject, :flag, :destroy ]

  def index
    @reviews_query = Review.includes(:user, :movie, :event)

    # Apply filters using concern method
    @reviews = filter_reviews(params).limit(50).to_a

    # Calculate stats using concern method
    @stats = calculate_review_stats
    @insights = review_insights

    # Get filter options for form
    @filter_options = get_review_filter_options

    # Additional data for dashboard
    @top_movies = top_reviewed_movies(5)
    @active_reviewers = most_active_reviewers(5)
  end

  def show
    @sentiment_analysis = analyze_review_sentiment(@review)
    @quality_score = calculate_review_quality_score(@review)
    @related_reviews = Review.joins(:event)
                            .where(events: { movie_id: @review.movie_id })
                            .where.not(id: @review.id)
                            .includes(:user, :event)
                            .order(created_at: :desc)
                            .limit(5)
  end

  def update
    if @review.update(review_params)
      log_review_action('updated', @review, review_params.to_h)

      respond_to do |format|
        format.json { render json: { status: 'success', message: 'Avis mis à jour' } }
        format.html { redirect_to admin_review_path(@review), notice: 'Avis mis à jour avec succès' }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @review.errors } }
        format.html { render :show, alert: 'Erreur lors de la mise à jour' }
      end
    end
  end

  # Moderation actions
  def approve
    approve_review_action(@review)
    log_review_action('approved', @review)

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Avis approuvé' } }
      format.html { redirect_to admin_review_path(@review), notice: 'Avis approuvé avec succès' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_review_path(@review), alert: 'Erreur lors de l\'approbation' }
    end
  end

  def reject
    reason = params[:reason] || 'Content violates community guidelines'
    reject_review_action(@review)
    log_review_action('rejected', @review, { reason: reason })

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Avis rejeté' } }
      format.html { redirect_to admin_review_path(@review), notice: 'Avis rejeté' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_review_path(@review), alert: 'Erreur lors du rejet' }
    end
  end

  def flag
    reason = params[:reason] || 'inappropriate_content'
    flag_review_action(@review, reason)
    log_review_action('flagged', @review, { reason: reason })

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Avis signalé' } }
      format.html { redirect_to admin_review_path(@review), notice: "Avis signalé pour: #{reason}" }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_review_path(@review), alert: 'Erreur lors du signalement' }
    end
  end

  def destroy
    movie_title = @review.movie.title
    user_name = @review.user.full_name

    @review.destroy
    log_review_action('deleted', @review, { movie: movie_title, user: user_name })

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Avis supprimé' } }
      format.html { redirect_to admin_reviews_path, notice: 'Avis supprimé avec succès' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_reviews_path, alert: 'Erreur lors de la suppression' }
    end
  end

  # Bulk operations
  def bulk_approve
    review_ids = params[:review_ids]
    return redirect_to admin_reviews_path, alert: 'Aucun avis sélectionné' if review_ids.blank?

    bulk_approve_reviews(review_ids)
    log_review_action('bulk_approved', nil, { count: review_ids.count, ids: review_ids })

    respond_to do |format|
      format.json { render json: { status: 'success', message: "#{review_ids.count} avis approuvés" } }
      format.html { redirect_to admin_reviews_path, notice: "#{review_ids.count} avis approuvés" }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_reviews_path, alert: 'Erreur lors de l\'approbation en masse' }
    end
  end

  def bulk_reject
    review_ids = params[:review_ids]
    return redirect_to admin_reviews_path, alert: 'Aucun avis sélectionné' if review_ids.blank?

    bulk_reject_reviews(review_ids)
    log_review_action('bulk_rejected', nil, { count: review_ids.count, ids: review_ids })

    respond_to do |format|
      format.json { render json: { status: 'success', message: "#{review_ids.count} avis rejetés" } }
      format.html { redirect_to admin_reviews_path, notice: "#{review_ids.count} avis rejetés" }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_reviews_path, alert: 'Erreur lors du rejet en masse' }
    end
  end

  def bulk_delete
    review_ids = params[:review_ids]
    return redirect_to admin_reviews_path, alert: 'Aucun avis sélectionné' if review_ids.blank?

    reviews_to_delete = Review.where(id: review_ids)
    count = reviews_to_delete.count

    bulk_delete_reviews(review_ids)
    log_review_action('bulk_deleted', nil, { count: count, ids: review_ids })

    respond_to do |format|
      format.json { render json: { status: 'success', message: "#{count} avis supprimés" } }
      format.html { redirect_to admin_reviews_path, notice: "#{count} avis supprimés" }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_reviews_path, alert: 'Erreur lors de la suppression en masse' }
    end
  end

  # Analytics and insights
  def analytics
    @comprehensive_stats = calculate_review_stats
    @insights = review_insights
    @top_movies = top_reviewed_movies(10)
    @active_reviewers = most_active_reviewers(10)

    # Monthly data for charts
    @monthly_data = (12.months.ago.to_date..Date.current).group_by(&:month).map do |month, dates|
      month_reviews = Review.where(created_at: dates.first.beginning_of_month..dates.first.end_of_month)
      {
        month: dates.first.strftime('%B %Y'),
        count: month_reviews.count,
        avg_rating: month_reviews.average(:rating)&.round(2) || 0
      }
    end

    # Sentiment analysis over time
    @sentiment_trends = (6.months.ago.to_date..Date.current).group_by(&:month).map do |month, dates|
      month_reviews = Review.where(created_at: dates.first.beginning_of_month..dates.first.end_of_month)
      sentiment_dist = calculate_sentiment_distribution(month_reviews)

      {
        month: dates.first.strftime('%B'),
        positive: sentiment_dist[:positive],
        negative: sentiment_dist[:negative],
        neutral: sentiment_dist[:neutral]
      }
    end

    respond_to do |format|
      format.html
      format.json { render json: { stats: @comprehensive_stats, insights: @insights } }
    end
  end

  # Export functionality
  def export
    reviews_scope = filter_reviews(params)
    @export_data = export_reviews_data(reviews_scope)

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          data: @export_data,
          filename: "reviews_export_#{Date.current.strftime('%Y%m%d')}.csv"
        }
      end
      format.csv do
        send_data generate_csv(@export_data),
                  filename: "reviews_export_#{Date.current.strftime('%Y%m%d')}.csv"
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_reviews_path, alert: 'Erreur lors de l\'export' }
    end
  end

  # Sentiment analysis endpoint
  def sentiment_analysis
    review_id = params[:id]
    review = Review.find(review_id)
    analysis = analyze_review_sentiment(review)
    quality_score = calculate_review_quality_score(review)

    respond_to do |format|
      format.json do
        render json: {
          sentiment: analysis,
          quality_score: quality_score,
          review_id: review.id
        }
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { error: 'Review not found' }, status: 404 }
    end
  end

  # Get statistics for dashboard widgets
  def stats
    respond_to do |format|
      format.json do
        render json: {
          stats: calculate_review_stats,
          insights: review_insights,
          recent_flagged: Review.where(status: :flagged).count,
          pending_moderation: Review.where(status: :pending).count,
          daily_reviews: Review.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day).count
        }
      end
    end
  end

  # Review quality report
  def quality_report
    @reviews_with_scores = Review.includes(:user, :movie, :event)
                                .limit(100)
                                .map do |review|
      {
        review: review,
        quality_score: calculate_review_quality_score(review),
        sentiment: analyze_review_sentiment(review)
      }
    end.sort_by { |item| -item[:quality_score] }

    @quality_distribution = @reviews_with_scores.group_by do |item|
      score = item[:quality_score]
      case score
      when 0..30 then 'Poor'
      when 31..60 then 'Average'
      when 61..80 then 'Good'
      when 81..100 then 'Excellent'
      end
    end

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

  # Generate CSV from export data
  def generate_csv(data)
    return '' if data.empty?

    headers = data.first.keys
    CSV.generate(headers: true) do |csv|
      csv << headers
      data.each { |row| csv << headers.map { |h| row[h] } }
    end
  end

  # Enhanced logging with admin context
  def log_review_action(action, review, details = {})
    review_info = review ? "review_id:#{review.id}" : 'multiple_reviews'
    Rails.logger.info "Admin Review Management: #{current_user.email} #{action} #{review_info} - #{details}"

    # FOR RGPD
    # AuditLog.create(
    #   admin_user: current_user,
    #   action: action,
    #   target_type: 'Review',
    #   target_id: review&.id,
    #   details: details,
    #   ip_address: request.remote_ip,
    #   user_agent: request.user_agent
    # )
  end
end
