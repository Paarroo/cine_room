class FavoritesController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @favorite_movies = current_user.favorite_movies.includes(:events, :reviews).approved
  end
  
  def create
    @movie = Movie.find(params[:movie_id])
    @favorite = current_user.favorites.build(movie: @movie)
    
    respond_to do |format|
      if @favorite.save
        format.json { 
          render json: { 
            status: 'success', 
            favorited: true,
            favorite_id: @favorite.id,
            count: @movie.favorites_count,
            message: 'Film ajouté aux favoris'
          }
        }
      else
        format.json { 
          render json: { 
            status: 'error', 
            message: 'Impossible d\'ajouter aux favoris' 
          } 
        }
      end
    end
  end
  
  def destroy
    @favorite = current_user.favorites.find(params[:id])
    @movie = @favorite.movie
    
    respond_to do |format|
      if @favorite.destroy
        format.json { 
          render json: { 
            status: 'success', 
            favorited: false,
            count: @movie.favorites_count,
            message: 'Film retiré des favoris'
          }
        }
        format.html { 
          redirect_to favorites_path, notice: 'Film retiré des favoris' 
        }
      else
        format.json { 
          render json: { 
            status: 'error', 
            message: 'Impossible de retirer des favoris' 
          } 
        }
        format.html { 
          redirect_to favorites_path, alert: 'Erreur lors de la suppression' 
        }
      end
    end
  end
end