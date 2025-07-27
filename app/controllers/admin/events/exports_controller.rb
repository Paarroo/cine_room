class Admin::Events::ExportsController < Admin::ApplicationController
  
  def show
    @event = Event.find(params[:event_id])
    
    respond_to do |format|
      format.csv do
        csv_data = generate_participations_csv(@event)
        send_data csv_data, 
                  type: 'text/csv',
                  filename: "event_#{@event.id}_participations_#{Date.current.strftime('%Y%m%d')}.csv"
      end
      format.json do
        participations_data = @event.participations.includes(:user).map do |participation|
          {
            id: participation.id,
            user_name: participation.user&.full_name,
            user_email: participation.user&.email,
            seats: participation.seats,
            status: participation.status,
            created_at: participation.created_at
          }
        end
        
        render json: {
          success: true,
          data: participations_data,
          filename: "event_#{@event.id}_participations_#{Date.current.strftime('%Y%m%d')}.csv"
        }
      end
    end
  end

  private

  def generate_participations_csv(event)
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'User Name', 'User Email', 'Seats', 'Status', 'Created At']
      
      event.participations.includes(:user).find_each do |participation|
        csv << [
          participation.id,
          participation.user&.full_name,
          participation.user&.email,
          participation.seats,
          participation.status,
          participation.created_at
        ]
      end
    end
  end
end