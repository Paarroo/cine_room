class Admin::BackupExportsController < Admin::ApplicationController
  
  def show
    respond_to do |format|
      format.csv do
        csv_data = generate_backup_csv
        send_data csv_data, 
                  type: 'text/csv',
                  filename: "database_backup_#{Date.current.strftime('%Y%m%d')}.csv"
      end
      format.json do
        backup_data = generate_backup_data
        
        render json: {
          success: true,
          data: backup_data,
          filename: "database_backup_#{Date.current.strftime('%Y%m%d')}.csv"
        }
      end
    end
  end

  private

  def generate_backup_csv
    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << ['Table', 'Records Count', 'Status', 'Backup Date']
      
      backup_data.each do |table_info|
        csv << [
          table_info[:table],
          table_info[:count],
          table_info[:status],
          table_info[:backup_date]
        ]
      end
    end
  end

  def generate_backup_data
    [
      { table: 'Users', count: User.count, status: 'OK', backup_date: Time.current },
      { table: 'Movies', count: Movie.count, status: 'OK', backup_date: Time.current },
      { table: 'Events', count: Event.count, status: 'OK', backup_date: Time.current },
      { table: 'Participations', count: Participation.count, status: 'OK', backup_date: Time.current },
      { table: 'Reviews', count: Review.count, status: 'OK', backup_date: Time.current }
    ]
  end
end