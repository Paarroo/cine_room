module ReviewsManagement
  extend ActiveSupport::Concern

  def approve_review_action(review)
    review.update!(
      status: :approved,
      moderated_by: current_user,
      moderated_at: Time.current
    )
  end

  def reject_review_action(review)
    review.update!(
      status: :rejected,
      moderated_by: current_user,
      moderated_at: Time.current
    )
  end

  def flag_review_action(review, reason = 'inappropriate_content')
    review.update!(
      status: :flagged,
      flag_reason: reason,
      flagged_by: current_user,
      flagged_at: Time.current
    )
  end

  # Bulk review operations
  def bulk_approve_reviews(review_ids)
    Review.where(id: review_ids).update_all(
      status: :approved,
      moderated_by_id: current_user.id,
      moderated_at: Time.current
    )
  end

  def bulk_reject_reviews(review_ids)
    Review.where(id: review_ids).update_all(
      status: :rejected,
      moderated_by_id: current_user.id,
      moderated_at: Time.current
    )
  end

  def bulk_delete_reviews(review_ids)
    Review.where(id: review_ids).destroy_all
  end

  # Review statistics and analytics
  def calculate_review_stats
    {
      total: Review.count,
      with_rating: Review.where.not(rating: nil).count,
      with_comment: Review.where.not(comment: [ nil, '' ]).count,
      recent: Review.where(created_at: 1.month.ago..Time.current).count,
      average_rating: Review.average(:rating)&.round(2) || 0,
      rating_distribution: Review.group(:rating).count,
      pending_moderation: Review.where(status: :pending).count,
      flagged: Review.where(status: :flagged).count
    }
  end

  # Advanced filtering and search
  def filter_reviews(params)
    reviews = Review.includes(:user, :movie, :event)

    # Filter by rating
    if params[:rating].present?
      reviews = reviews.where(rating: params[:rating])
    end

    # Filter by rating range
    if params[:min_rating].present?
      reviews = reviews.where('rating >= ?', params[:min_rating])
    end
    if params[:max_rating].present?
      reviews = reviews.where('rating <= ?', params[:max_rating])
    end

    # Filter by content type
    case params[:content_type]
    when 'with_comment'
      reviews = reviews.where.not(comment: [ nil, '' ])
    when 'rating_only'
      reviews = reviews.where(comment: [ nil, '' ])
    when 'with_rating'
      reviews = reviews.where.not(rating: nil)
    end
