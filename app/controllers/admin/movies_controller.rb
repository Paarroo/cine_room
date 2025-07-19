class Admin::MoviesController < Admin::ApplicationController
  def index
    @movies = Movie.includes(:user, :events)
  end

  def show
    @movie = Movie.find(params[:id])
  end

  def update_validation
    @movie = Movie.find(params[:id])
    @movie.update(validation_status: params[:status])
    redirect_to admin_movie_path(@movie)
  end
end
