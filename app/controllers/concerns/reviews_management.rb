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
      pending_moderation: 0,
         flagged: 0
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
      score += [ comment_length / 5, 40 ].min
    end

    # Sentiment analysis bonus
    sentiment = analyze_review_sentiment(review)
    score += 10 if sentiment[:sentiment] != 'neutral'

    # Recent review bonus (within 48h of event) - CORRIGÉ
    if review.event&.event_date.present?
      days_diff = (review.created_at.to_date - review.event.event_date).to_i
      score += 20 if days_diff <= 2 && days_diff >= 0
    end

    [ score, 100 ].min
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

  # Get filter options for forms
  def get_review_filter_options
    {
      ratings: (1..5).map { |r| [ r, r ] },
      content_types: [
        [ 'All Reviews', '' ],
        [ 'With Comments', 'with_comment' ],
        [ 'Rating Only', 'rating_only' ],
        [ 'With Rating', 'with_rating' ]
      ],
      time_periods: [
        [ 'All Time', '' ],
        [ 'Today', 'today' ],
        [ 'This Week', 'week' ],
        [ 'This Month', 'month' ],
        [ 'Recent (30 days)', 'recent' ]
      ],
      genres: Movie.joins(:reviews).distinct.pluck(:genre).compact.sort.map { |g| [ g, g ] },
      user_roles: User.roles.keys.map { |role| [ role.humanize, role ] },
      event_statuses: Event.statuses.keys.map { |status| [ status.humanize, status ] },
      sort_options: [
        [ 'Newest First', 'newest' ],
        [ 'Oldest First', 'oldest' ],
        [ 'Highest Rating', 'rating_desc' ],
        [ 'Lowest Rating', 'rating_asc' ]
      ]
    }
  end

  # Review insights for dashboard
  def review_insights
    recent_reviews = Review.where(created_at: 1.month.ago..Time.current)

    {
      monthly_growth: calculate_monthly_growth,
      average_rating_trend: calculate_rating_trend,
      top_rated_movies_this_month: top_reviewed_movies(5),
      sentiment_distribution: calculate_sentiment_distribution(recent_reviews),
      review_quality_average: calculate_average_quality_score(recent_reviews),
      response_time_after_events: calculate_average_response_time
    }
  end

  private

  # Calculate monthly growth in reviews
  def calculate_monthly_growth
    current_month = Review.where(created_at: 1.month.ago..Time.current).count
    previous_month = Review.where(created_at: 2.months.ago..1.month.ago).count

    return 0 if previous_month.zero?

    ((current_month - previous_month).to_f / previous_month * 100).round(1)
  end

  # Calculate rating trend over time
  def calculate_rating_trend
    last_month = Review.where(created_at: 1.month.ago..Time.current).average(:rating) || 0
    previous_month = Review.where(created_at: 2.months.ago..1.month.ago).average(:rating) || 0

    {
      current: last_month.round(2),
      previous: previous_month.round(2),
      trend: last_month > previous_month ? 'up' : (last_month < previous_month ? 'down' : 'stable')
    }
  end

  # Calculate sentiment distribution
  def calculate_sentiment_distribution(reviews_scope)
    sentiments = { positive: 0, negative: 0, neutral: 0 }

    reviews_scope.find_each do |review|
      sentiment = analyze_review_sentiment(review)[:sentiment]
      sentiments[sentiment.to_sym] += 1
    end

    sentiments
  end

  # Calculate average quality score
  def calculate_average_quality_score(reviews_scope)
    total_score = 0
    count = 0

    reviews_scope.find_each do |review|
      score = 0

      # Rating provided (+20 points)
      score += 20 if review.rating.present?

      # Comment length (up to 40 points)
      if review.comment.present?
        comment_length = review.comment.length
        score += [ comment_length / 5, 40 ].min
      end

      # Recent review bonus (within 48h of event)
      if review.event&.event_date.present?
        days_diff = (review.created_at.to_date - review.event.event_date).to_i
        score += 20 if days_diff <= 2 && days_diff >= 0
      end

      total_score += [ score, 100 ].min
      count += 1
    end

    count.zero? ? 0 : (total_score.to_f / count).round(1)
  end

  # Calculate average response time after events
  def calculate_average_response_time
    reviews_with_events = Review.joins(:event)
                               .where.not(events: { event_date: nil })
                               .where('reviews.created_at::date > events.event_date')

    return 0 if reviews_with_events.empty?

    total_days = 0
    count = 0

    reviews_with_events.find_each do |review|
      days_diff = (review.created_at.to_date - review.event.event_date).to_i
      total_days += days_diff if days_diff > 0
      count += 1
    end

    count.zero? ? 0 : (total_days.to_f / count).round(1)
  end

  # Log review actions for audit
  def log_review_action(action, review, details = {})
    Rails.logger.info "Review Management: #{current_user.email} #{action} review #{review.id} - #{details}"
  end
end
