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

    # Filter by time period
    case params[:time_period]
    when 'today'
      reviews = reviews.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day)
    when 'week'
      reviews = reviews.where(created_at: 1.week.ago..Time.current)
    when 'month'
      reviews = reviews.where(created_at: 1.month.ago..Time.current)
    when 'recent'
      reviews = reviews.where(created_at: 1.month.ago..Time.current)
    end

    # Filter by movie genre
    if params[:genre].present?
      reviews = reviews.joins(:movie).where(movies: { genre: params[:genre] })
    end

    # Filter by user role
    if params[:user_role].present?
      reviews = reviews.joins(:user).where(users: { role: params[:user_role] })
    end

    # Search in comments
    if params[:q].present?
      reviews = reviews.where(
        "comment ILIKE ? OR users.first_name ILIKE ? OR users.last_name ILIKE ? OR movies.title ILIKE ?",
        "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%"
      ).joins(:user, :movie)
    end

    # Filter by event status
    if params[:event_status].present?
      reviews = reviews.joins(:event).where(events: { status: params[:event_status] })
    end

    # Sort options
    case params[:sort]
    when 'rating_desc'
      reviews = reviews.order(rating: :desc, created_at: :desc)
    when 'rating_asc'
      reviews = reviews.order(rating: :asc, created_at: :desc)
    when 'newest'
      reviews = reviews.order(created_at: :desc)
    when 'oldest'
      reviews = reviews.order(created_at: :asc)
    else
      reviews = reviews.order(created_at: :desc)
    end

    reviews
  end

  # Review sentiment analysis (basic)
  def analyze_review_sentiment(review)
    return { sentiment: 'neutral', score: 0 } if review.comment.blank?

    comment_text = review.comment.downcase

    positive_words = %w[excellent great amazing wonderful fantastic love perfect beautiful outstanding incredible]
    negative_words = %w[terrible awful horrible hate disappointing worst bad poor disgusting unbearable]

    positive_count = positive_words.count { |word| comment_text.include?(word) }
    negative_count = negative_words.count { |word| comment_text.include?(word) }

    score = positive_count - negative_count

    sentiment = if score > 0
                  'positive'
    elsif score < 0
                  'negative'
    else
                  'neutral'
    end

    {
      sentiment: sentiment,
      score: score,
      positive_words_found: positive_count,
      negative_words_found: negative_count
    }
  end

  # Get top reviewed movies
  def top_reviewed_movies(limit = 10)
    Movie.joins(:reviews)
         .group('movies.id, movies.title')
         .select('movies.*, COUNT(reviews.id) as reviews_count, AVG(reviews.rating) as avg_rating')
         .order('reviews_count DESC, avg_rating DESC')
         .limit(limit)
  end

  # Get most active reviewers
  def most_active_reviewers(limit = 10)
    User.joins(:reviews)
        .group('users.id, users.first_name, users.last_name, users.email')
        .select('users.*, COUNT(reviews.id) as reviews_count, AVG(reviews.rating) as avg_rating_given')
        .order('reviews_count DESC, avg_rating_given DESC')
        .limit(limit)
  end

  # Review quality scoring
  def calculate_review_quality_score(review)
    score = 0

    # Rating provided (+20 points)
    score += 20 if review.rating.present?

    # Comment length (up to 40 points)
    if review.comment.present?
      comment_length = review.comment.length
      score += [ comment_length / 5, 40 ].min # 1 point per 5 characters, max 40
    end

    # Helpfulness votes (if implemented in future)
    # score += (review.helpful_votes || 0) * 2

    # Sentiment analysis bonus
    sentiment = analyze_review_sentiment(review)
    score += 10 if sentiment[:sentiment] != 'neutral'

    # Recent review bonus (within 48h of event)
    if review.event.event_date.present?
      time_diff = review.created_at - review.event.event_date
      score += 20 if time_diff <= 2.days && time_diff >= 0
    end

    [ score, 100 ].min # Cap at 100
  end

  # Export reviews data
  def export_reviews_data(reviews_scope = Review.all)
    reviews_scope.includes(:user, :movie, :event)
                 .limit(1000)
                 .map do |review|
      sentiment = analyze_review_sentiment(review)
      quality_score = calculate_review_quality_score(review)

      {
        id: review.id,
        user_name: review.user&.full_name,
        user_email: review.user&.email,
        movie_title: review.movie&.title,
        movie_genre: review.movie&.genre,
        event_title: review.event&.title,
        event_date: review.event&.event_date&.strftime('%Y-%m-%d'),
        rating: review.rating,
        comment: review.comment,
        comment_length: review.comment&.length || 0,
        sentiment: sentiment[:sentiment],
        sentiment_score: sentiment[:score],
        quality_score: quality_score,
        created_at: review.created_at.strftime('%Y-%m-%d %H:%M:%S'),
        days_after_event: review.event&.event_date ? (review.created_at.to_date - review.event.event_date).to_i : nil
      }
    end
  end
