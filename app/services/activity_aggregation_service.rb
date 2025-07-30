class ActivityAggregationService
  def initialize(limit = 5)
    @limit = limit
  end

  def recent_activities
    activities = []
    activities += participation_activities
    activities += movie_activities
    activities += user_activities
    activities += event_activities
    
    activities.sort_by { |a| a[:created_at] }.reverse.first(@limit)
  end

  def recent_activities_by_type(type)
    case type.to_sym
    when :participations
      participation_activities
    when :movies
      movie_activities
    when :users
      user_activities
    when :events
      event_activities
    else
      []
    end
  end

  def activity_summary
    {
      participations: participation_activities.count,
      movies: movie_activities.count,
      users: user_activities.count,
      events: event_activities.count,
      total: recent_activities.count
    }
  end

  private

  def participation_activities
    Participation.includes(:user, :event)
                 .order(created_at: :desc)
                 .limit(@limit)
                 .map do |participation|
      {
        type: 'participation',
        id: participation.id,
        title: "Nouvelle participation - #{participation.event&.title}",
        description: "#{participation.user&.full_name} s'est inscrit",
        user: participation.user&.full_name,
        created_at: participation.created_at,
        time_ago: time_ago_in_words(participation.created_at),
        status: participation.status,
        icon: 'ticket'
      }
    end
  end

  def movie_activities
    Movie.includes(:user)
         .order(created_at: :desc)
         .limit(@limit)
         .map do |movie|
      {
        type: 'movie',
        id: movie.id,
        title: "Nouveau film - #{movie.title}",
        description: "Film ajouté par #{movie.user&.full_name}",
        user: movie.user&.full_name,
        created_at: movie.created_at,
        time_ago: time_ago_in_words(movie.created_at),
        status: movie.validation_status,
        icon: 'film'
      }
    end
  end

  def user_activities
    User.order(created_at: :desc)
        .limit(@limit)
        .map do |user|
      {
        type: 'user',
        id: user.id,
        title: "Nouvel utilisateur - #{user.full_name}",
        description: "Inscription de #{user.email}",
        user: user.full_name,
        created_at: user.created_at,
        time_ago: time_ago_in_words(user.created_at),
        status: user.role,
        icon: 'user'
      }
    end
  end

  def event_activities
    Event.includes(:movie, :user)
         .order(created_at: :desc)
         .limit(@limit)
         .map do |event|
      {
        type: 'event',
        id: event.id,
        title: "Nouvel événement - #{event.title}",
        description: "Événement créé pour #{event.movie&.title}",
        user: event.user&.full_name,
        created_at: event.created_at,
        time_ago: time_ago_in_words(event.created_at),
        status: event.status,
        icon: 'calendar'
      }
    end
  end

  def time_ago_in_words(datetime)
    return 'Date inconnue' unless datetime

    diff = Time.current - datetime
    
    case diff
    when 0..59
      'Il y a moins d\'une minute'
    when 60..3599
      minutes = (diff / 60).round
      "Il y a #{minutes} minute#{'s' if minutes > 1}"
    when 3600..86399
      hours = (diff / 3600).round
      "Il y a #{hours} heure#{'s' if hours > 1}"
    when 86400..2591999
      days = (diff / 86400).round
      "Il y a #{days} jour#{'s' if days > 1}"
    else
      datetime.strftime('%d/%m/%Y')
    end
  end
end