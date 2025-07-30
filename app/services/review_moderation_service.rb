class ReviewModerationService
  def initialize(reviews_scope = nil)
    @reviews_scope = reviews_scope || Review.all
  end

  def calculate_statistics
    {
      total: @reviews_scope.count,
      pending: @reviews_scope.where(status: :pending).count,
      approved: @reviews_scope.where(status: :approved).count,
      rejected: @reviews_scope.where(status: :rejected).count,
      flagged: @reviews_scope.where(status: :flagged).count,
      average_rating: @reviews_scope.average(:rating)&.round(2) || 0,
      total_this_month: @reviews_scope.where(created_at: 1.month.ago..Time.current).count
    }
  end

  def calculate_insights
    {
      sentiment_distribution: calculate_sentiment_distribution(@reviews_scope),
      quality_distribution: calculate_quality_distribution,
      moderation_backlog: @reviews_scope.where(status: :pending).count,
      flagged_reviews: @reviews_scope.where(status: :flagged).count
    }
  end

  def analyze_review_sentiment(review)
    return { sentiment: 'neutral', confidence: 0 } unless review.comment.present?

    comment = review.comment.downcase
    
    positive_words = ['excellent', 'génial', 'superbe', 'formidable', 'parfait', 'incroyable', 
                     'magnifique', 'extraordinaire', 'fantastique', 'merveilleux', 'sublime',
                     'impressionnant', 'remarquable', 'exceptionnel', 'brillant', 'love', 'adore']
                     
    negative_words = ['nul', 'terrible', 'horrible', 'affreux', 'décevant', 'ennuyeux', 
                     'mauvais', 'catastrophique', 'lamentable', 'pathétique', 'navrant',
                     'déteste', 'hate', 'boring', 'awful', 'worst', 'bad']

    positive_score = positive_words.count { |word| comment.include?(word) }
    negative_score = negative_words.count { |word| comment.include?(word) }
    
    # Factor in rating
    rating_sentiment = case review.rating
    when 1..2 then -2
    when 3 then 0
    when 4..5 then 2
    else 0
    end

    total_positive = positive_score + (rating_sentiment > 0 ? rating_sentiment : 0)
    total_negative = negative_score + (rating_sentiment < 0 ? rating_sentiment.abs : 0)

    if total_positive > total_negative
      sentiment = 'positive'
      confidence = [(total_positive - total_negative) * 0.3, 1.0].min
    elsif total_negative > total_positive
      sentiment = 'negative'
      confidence = [(total_negative - total_positive) * 0.3, 1.0].min
    else
      sentiment = 'neutral'
      confidence = 0.1
    end

    {
      sentiment: sentiment,
      confidence: confidence.round(2),
      positive_score: total_positive,
      negative_score: total_negative,
      rating_influence: rating_sentiment
    }
  end

  def calculate_review_quality_score(review)
    score = 0
    
    # Comment length (0-30 points)
    if review.comment.present?
      comment_length = review.comment.length
      case comment_length
      when 0..10 then score += 5
      when 11..50 then score += 15
      when 51..200 then score += 25
      when 201..Float::INFINITY then score += 30
      end
    end

    # Rating consistency (0-20 points)
    if review.rating.present?
      case review.rating
      when 1..2 then score += 10 # Extreme ratings need justification
      when 3 then score += 20    # Balanced ratings are valuable
      when 4..5 then score += 15
      end
    end

    # User credibility (0-25 points)
    user_reviews_count = Review.where(user: review.user).count
    case user_reviews_count
    when 1 then score += 5       # New user
    when 2..5 then score += 15   # Regular user
    when 6..Float::INFINITY then score += 25 # Power user
    end

    # Recency bonus (0-15 points)
    days_old = (Time.current - review.created_at) / 1.day
    case days_old
    when 0..7 then score += 15   # Very recent
    when 8..30 then score += 10  # Recent
    when 31..90 then score += 5  # Somewhat old
    end

    # Engagement factor (0-10 points)
    # This could be based on likes, replies, etc. if available
    score += 5 # Base engagement score

    [score, 100].min # Cap at 100
  end

  def bulk_approve_reviews(review_ids)
    reviews = Review.where(id: review_ids, status: :pending)
    
    if reviews.empty?
      return { success: false, error: 'Aucune review éligible trouvée' }
    end

    approved_count = 0
    reviews.find_each do |review|
      if review.update(status: :approved)
        approved_count += 1
      end
    end

    {
      success: true,
      message: "#{approved_count} avis approuvés",
      count: approved_count
    }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def bulk_reject_reviews(review_ids)
    reviews = Review.where(id: review_ids).where.not(status: :rejected)
    
    if reviews.empty?
      return { success: false, error: 'Aucune review éligible trouvée' }
    end

    rejected_count = 0
    reviews.find_each do |review|
      if review.update(status: :rejected)
        rejected_count += 1
      end
    end

    {
      success: true,
      message: "#{rejected_count} avis rejetés",
      count: rejected_count
    }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def bulk_delete_reviews(review_ids)
    reviews = Review.where(id: review_ids)
    count = reviews.count
    
    reviews.destroy_all
    
    {
      success: true,
      message: "#{count} avis supprimés",
      count: count
    }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def calculate_monthly_data
    (12.months.ago.to_date..Date.current).group_by(&:month).map do |month, dates|
      month_reviews = @reviews_scope.where(created_at: dates.first.beginning_of_month..dates.first.end_of_month)
      {
        month: dates.first.strftime('%B %Y'),
        count: month_reviews.count,
        avg_rating: month_reviews.average(:rating)&.round(2) || 0
      }
    end
  end

  def calculate_sentiment_trends
    (6.months.ago.to_date..Date.current).group_by(&:month).map do |month, dates|
      month_reviews = @reviews_scope.where(created_at: dates.first.beginning_of_month..dates.first.end_of_month)
      sentiment_dist = calculate_sentiment_distribution(month_reviews)

      {
        month: dates.first.strftime('%B'),
        positive: sentiment_dist[:positive],
        negative: sentiment_dist[:negative],
        neutral: sentiment_dist[:neutral]
      }
    end
  end

  def top_reviewed_movies(limit = 10)
    Movie.joins(:reviews)
         .where(reviews: { status: :approved })
         .group('movies.id')
         .order('COUNT(reviews.id) DESC')
         .limit(limit)
  end

  def most_active_reviewers(limit = 10)
    User.joins(:reviews)
        .where(reviews: { status: :approved })
        .group('users.id')
        .order('COUNT(reviews.id) DESC')
        .limit(limit)
  end

  def export_data(reviews_scope)
    reviews_scope.includes(:user, :movie, :event).map do |review|
      sentiment = analyze_review_sentiment(review)
      quality = calculate_review_quality_score(review)
      
      {
        id: review.id,
        user_name: review.user&.full_name || 'N/A',
        user_email: review.user&.email || 'N/A',
        movie_title: review.movie&.title || 'N/A',
        event_title: review.event&.title || 'N/A',
        rating: review.rating,
        comment: review.comment,
        status: review.status.humanize,
        sentiment: sentiment[:sentiment],
        sentiment_confidence: sentiment[:confidence],
        quality_score: quality,
        created_at: review.created_at.strftime('%d/%m/%Y %H:%M')
      }
    end
  end

  def get_filter_options
    {
      statuses: Review.statuses.keys.map { |s| [s.humanize, s] },
      movies: Movie.joins(:reviews).distinct.limit(20).pluck(:title, :id),
      ratings: (1..5).map { |r| [r, r] }
    }
  end

  def generate_quality_report
    reviews_with_scores = @reviews_scope.includes(:user, :movie, :event)
                                       .limit(100)
                                       .map do |review|
      {
        review: review,
        quality_score: calculate_review_quality_score(review),
        sentiment: analyze_review_sentiment(review)
      }
    end.sort_by { |item| -item[:quality_score] }

    quality_distribution = reviews_with_scores.group_by do |item|
      score = item[:quality_score]
      case score
      when 0..30 then 'Poor'
      when 31..60 then 'Average'
      when 61..80 then 'Good'
      when 81..100 then 'Excellent'
      end
    end

    {
      reviews_with_scores: reviews_with_scores,
      quality_distribution: quality_distribution
    }
  end

  private

  def calculate_sentiment_distribution(reviews_scope)
    total = reviews_scope.count
    return { positive: 0, negative: 0, neutral: 0 } if total.zero?

    sentiments = { positive: 0, negative: 0, neutral: 0 }
    
    reviews_scope.find_each do |review|
      sentiment = analyze_review_sentiment(review)[:sentiment]
      sentiments[sentiment.to_sym] += 1
    end

    {
      positive: ((sentiments[:positive].to_f / total) * 100).round(1),
      negative: ((sentiments[:negative].to_f / total) * 100).round(1),
      neutral: ((sentiments[:neutral].to_f / total) * 100).round(1)
    }
  end

  def calculate_quality_distribution
    total = @reviews_scope.count
    return { poor: 0, average: 0, good: 0, excellent: 0 } if total.zero?

    distribution = { poor: 0, average: 0, good: 0, excellent: 0 }
    
    @reviews_scope.find_each do |review|
      score = calculate_review_quality_score(review)
      case score
      when 0..30 then distribution[:poor] += 1
      when 31..60 then distribution[:average] += 1
      when 61..80 then distribution[:good] += 1
      when 81..100 then distribution[:excellent] += 1
      end
    end

    distribution.transform_values { |count| ((count.to_f / total) * 100).round(1) }
  end
end