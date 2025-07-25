class Admin::MoviesExportsController < Admin::ApplicationController
  
  def show
    respond_to do |format|
      format.csv do
        csv_data = generate_movies_csv
        send_data csv_data, 
                  type: 'text/csv',
                  filename: "movies_export_#{Date.current.strftime('%Y%m%d')}.csv"
      end
      format.json do
        movies_data = Movie.includes(:user)
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
        
        render json: {
          success: true,
          data: movies_data,
          filename: "movies_export_#{Date.current.strftime('%Y%m%d')}.csv"
        }
      end
    end
  end

  private

  def generate_movies_csv
    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Title', 'Director', 'Year', 'Validation Status', 'Created At']
      
      Movie.includes(:user).find_each do |movie|
        csv << [
          movie.id,
          movie.title,
          movie.director,
          movie.year,
          movie.validation_status,
          movie.created_at
        ]
      end
    end
  end
end