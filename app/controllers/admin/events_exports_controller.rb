class Admin::EventsExportsController < Admin::ApplicationController
  
  def show
    respond_to do |format|
      format.csv do
        csv_data = generate_events_csv
        send_data csv_data, 
                  type: 'text/csv',
                  filename: "events_export_#{Date.current.strftime('%Y%m%d')}.csv"
      end
      format.json do
        events_data = Event.includes(:movie)
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
        
        render json: {
          success: true,
          data: events_data,
          filename: "events_export_#{Date.current.strftime('%Y%m%d')}.csv"
        }
      end
    end
  end

  private

  def generate_events_csv
    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Title', 'Venue', 'Date', 'Max Capacity', 'Status']
      
      Event.includes(:movie).find_each do |event|
        csv << [
          event.id,
          event.title,
          event.venue_name,
          event.event_date,
          event.max_capacity,
          event.status
        ]
      end
    end
  end
end