class Admin::Movies::ExportsController < Admin::ApplicationController
  
  def show
    @movie = Movie.find(params[:movie_id])
    
    respond_to do |format|
      format.csv do
        csv_data = generate_movie_csv(@movie)
        send_data csv_data, 
                  type: 'text/csv',
                  filename: "movie_#{@movie.id}_export_#{Date.current.strftime('%Y%m%d')}.csv"
      end
      format.json do
        render json: {
          success: true,
          data: [@movie.attributes],
          filename: "movie_#{@movie.id}_export_#{Date.current.strftime('%Y%m%d')}.csv"
        }
      end
    end
  end

  private

  def generate_movie_csv(movie)
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Title', 'Director', 'Year', 'Genre', 'Validation Status', 'Created At']
      csv << [movie.id, movie.title, movie.director, movie.year, movie.genre, movie.validation_status, movie.created_at]
    end
  end
end