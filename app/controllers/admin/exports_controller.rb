class Admin::ExportsController < Admin::ApplicationController
  
  # RESTful export endpoint
  def show
    data_type = params[:type] || 'users'
    filename = "#{data_type}_export_#{Date.current.strftime('%Y%m%d')}.csv"

    case data_type
    when 'users'
      data = export_users_data
    when 'events'
      data = export_events_data
    when 'movies'
      data = export_movies_data
    when 'participations'
      data = export_participations_data
    else
      data = []
    end

    respond_to do |format|
      format.csv do
        send_data generate_csv(data), 
                  filename: filename,
                  type: 'text/csv',
                  disposition: 'attachment'
      end
      format.json do
        render json: {
          success: true,
          data: data,
          filename: filename
        }
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.csv { redirect_to admin_root_path, alert: "Erreur lors de l'export: #{e.message}" }
      format.json { render json: { error: e.message }, status: 500 }
    end
  end

  private

  # Export users data to CSV format
  def export_users_data
    User.select(:id, :email, :first_name, :last_name, :role, :created_at)
        .limit(1000)
        .map do |user|
      {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        role: user.role,
        created_at: user.created_at
      }
    end
  end

  # Export events data to CSV format
  def export_events_data
    Event.includes(:movie)
         .select(:id, :title, :venue_name, :event_date, :max_capacity, :status)
         .limit(1000)
         .map do |event|
      {
        id: event.id,
        title: event.title,
        venue_name: event.venue_name,
        event_date: event.event_date,
        max_capacity: event.max_capacity,
        status: event.status
      }
    end
  end

  # Export movies data to CSV format
  def export_movies_data
    Movie.includes(:user)
         .select(:id, :title, :director, :year, :validation_status, :created_at)
         .limit(1000)
         .map do |movie|
      {
        id: movie.id,
        title: movie.title,
        director: movie.director,
        year: movie.year,
        validation_status: movie.validation_status,
        created_at: movie.created_at
      }
    end
  end

  # Export participations data to CSV format
  def export_participations_data
    Participation.includes(:user, :event)
                 .select(:id, :user_id, :event_id, :seats, :status, :created_at)
                 .limit(1000)
                 .map do |participation|
      {
        id: participation.id,
        user_name: participation.user&.full_name,
        user_email: participation.user&.email,
        event_title: participation.event&.title,
        seats: participation.seats,
        status: participation.status,
        created_at: participation.created_at
      }
    end
  end

  def generate_csv(data)
    return "" if data.empty?

    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << data.first.keys
      data.each do |row|
        csv << row.values
      end
    end
  end
end