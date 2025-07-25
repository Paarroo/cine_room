class Admin::ExportsController < Admin::ApplicationController
  
  # RESTful export endpoint
  def show
    data_type = params[:type] || 'users'

    respond_to do |format|
      format.json do
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
          data = { error: 'Type non supporté' }
        end

        render json: {
          success: true,
          data: data,
          filename: "#{data_type}_export_#{Date.current.strftime('%Y%m%d')}.csv"
        }
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { error: e.message }, status: 500 }
    end
  end

  private

  # Export users data to CSV format
  def export_users_data
    User.select(:id, :email, :first_name, :last_name, :role, :created_at)
        .limit(1000)
        .map(&:attributes)
  end

  # Export events data to CSV format
  def export_events_data
    Event.includes(:movie)
         .select(:id, :title, :venue_name, :event_date, :max_capacity, :status)
         .limit(1000)
         .map(&:attributes)
  end

  # Export movies data to CSV format
  def export_movies_data
    Movie.includes(:user)
         .select(:id, :title, :director, :year, :validation_status, :created_at)
         .limit(1000)
         .map(&:attributes)
  end

  # Export participations data to CSV format
  def export_participations_data
    Participation.includes(:user, :event)
                 .select(:id, :user_id, :event_id, :seats, :status, :created_at)
                 .limit(1000)
                 .map(&:attributes)
  end
end