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
