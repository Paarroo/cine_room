class Admin::ParticipationsExportsController < Admin::ApplicationController
  
  def show
    respond_to do |format|
      format.csv do
        csv_data = generate_participations_csv
        send_data csv_data, 
                  type: 'text/csv',
                  filename: "participations_export_#{Date.current.strftime('%Y%m%d')}.csv"
      end
      format.json do
        participations_data = Participation.includes(:user, :event)
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
        
        render json: {
          success: true,
          data: participations_data,
          filename: "participations_export_#{Date.current.strftime('%Y%m%d')}.csv"
        }
      end
    end
  end

  private

  def generate_participations_csv
    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'User Name', 'User Email', 'Event Title', 'Seats', 'Status', 'Created At']
      
      Participation.includes(:user, :event).find_each do |participation|
        csv << [
          participation.id,
          participation.user&.full_name,
          participation.user&.email,
          participation.event&.title,
          participation.seats,
          participation.status,
          participation.created_at
        ]
      end
    end
  end
end