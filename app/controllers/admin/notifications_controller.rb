class Admin::NotificationsController < Admin::BaseController
  def poll
    notifications = []

    new_participations = Participation.where(created_at: 5.minutes.ago..Time.current)
                                    .includes(:event)

    new_participations.each do |participation|
      notifications << {
        type: 'new_participation',
        event_title: participation.event.title,
        user_name: participation.user&.full_name,
        created_at: participation.created_at
      }
    end
    pending_movies = Movie.where(validation_status: :pending)
                         .where(created_at: 1.hour.ago..Time.current)

    pending_movies.each do |movie|
      notifications << {
        type: 'movie_validation_needed',
        movie_title: movie.title,
        creator_name: movie.user&.full_name,
        created_at: movie.created_at
      }
    end

    sold_out_events = Event.where(status: :sold_out)
                          .where(updated_at: 1.hour.ago..Time.current)

    sold_out_events.each do |event|
      notifications << {
        type: 'event_sold_out',
        event_title: event.title,
        updated_at: event.updated_at
      }
    end

    render json: notifications.sort_by { |n| n[:created_at] || n[:updated_at] }.reverse
  end
end
