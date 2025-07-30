class ReviewViewService
  def initialize
  end

  def prepare_index_data(reviews)
    service = ReviewModerationService.new(Review.all)
    
    {
      stats: service.calculate_statistics,
      insights: service.calculate_insights,
      filter_options: service.get_filter_options,
      top_movies: service.top_reviewed_movies(5),
      active_reviewers: service.most_active_reviewers(5)
    }
  end

  def prepare_show_data(review)
    service = ReviewModerationService.new
    
    {
      sentiment_analysis: service.analyze_review_sentiment(review),
      quality_score: service.calculate_review_quality_score(review),
      related_reviews: find_related_reviews(review)
    }
  end

  def prepare_analytics_data
    service = ReviewModerationService.new(Review.all)
    
    {
      comprehensive_stats: service.calculate_statistics,
      insights: service.calculate_insights,
      top_movies: service.top_reviewed_movies(10),
      active_reviewers: service.most_active_reviewers(10),
      monthly_data: service.calculate_monthly_data,
      sentiment_trends: service.calculate_sentiment_trends
    }
  end

  def prepare_quality_report_data
    service = ReviewModerationService.new
    service.generate_quality_report
  end

  def prepare_stats_data
    service = ReviewModerationService.new
    {
      stats: service.calculate_statistics,
      insights: service.calculate_insights,
      recent_flagged: Review.where(status: :flagged).count,
      pending_moderation: Review.where(status: :pending).count,
      daily_reviews: Review.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day).count
    }
  end

  def prepare_export_data(reviews_scope)
    service = ReviewModerationService.new
    service.export_data(reviews_scope)
  end

  def analyze_single_review(review)
    service = ReviewModerationService.new
    {
      sentiment: service.analyze_review_sentiment(review),
      quality_score: service.calculate_review_quality_score(review),
      review_id: review.id
    }
  end

  private

  def find_related_reviews(review)
    Review.joins(:event)
          .where(events: { movie_id: review.movie_id })
          .where.not(id: review.id)
          .includes(:user, :event)
          .order(created_at: :desc)
          .limit(5)
  end
end