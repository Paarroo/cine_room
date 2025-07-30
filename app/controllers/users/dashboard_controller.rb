class Users::DashboardController < ApplicationController
  require "csv"

  before_action :authenticate_user!
  before_action :set_user

  def show
    @user = current_user
    @upcoming_participations = @user.participations.upcoming.includes(:event)
    @past_participations = @user.participations.past.includes(:event)
    @published_movies = @user.movies
    
    if @user.creator?
      @created_events = @user.created_events
    end
  end


  def upcoming_participations
    @upcoming_participations = @user.participations.joins(:event).where("event_date >= ?", Date.today).order("events.event_date ASC")
  end

  def past_participations
    @past_participations = @user.participations.joins(:event).where("event_date < ?", Date.today).order("events.event_date DESC")
  end

  def edit_profile

  end

  def update_profile

    if @user.update(profile_params)
      redirect_to users_dashboard_path(current_user), notice: "Profil mis à jour."
    else
      render :edit_profile, status: :unprocessable_entity
    end
  end

  def export
    respond_to do |format|
      format.json do
        render json: {
          first_name: @user.first_name,
          last_name: @user.last_name,
          email: @user.email,
          role: @user.role,
          movies: @user.movies.pluck(:title),
          reviews: @user.reviews.pluck(:content)
        }
      end

      format.csv do
        csv_data = CSV.generate(headers: true) do |csv|
          csv << %w[Champ Valeur]
          csv << ["Prénom", @user.first_name]
          csv << ["Nom", @user.last_name]
          csv << ["Email", @user.email]
          csv << ["Rôle", @user.role]
          csv << ["Bio", @user.bio]
          csv << ["Date d'inscription", @user.created_at.strftime("%d/%m/%Y")]
          csv << ["Nombre de films", @user.movies.count]
          csv << ["Nombre de critiques", @user.reviews.count]
          csv << ["Nombre de participations", @user.participations.count]
          csv << ["Nombre de favoris", @user.favorites.count]
          
          # Add participation details
          if @user.participations.any?
            csv << ["", ""] # Empty row for separation
            csv << ["PARTICIPATIONS", ""]
            csv << ["Événement", "Date", "Film", "Places", "Statut"]
            @user.participations.includes(:event => :movie).each do |participation|
              csv << [
                participation.event.title,
                participation.event.event_date.strftime("%d/%m/%Y"),
                participation.event.movie.title,
                participation.seats,
                participation.status
              ]
            end
          end
          
          # Add reviews details
          if @user.reviews.any?
            csv << ["", ""] # Empty row for separation
            csv << ["AVIS ET CRITIQUES", ""]
            csv << ["Film", "Note", "Commentaire", "Date"]
            @user.reviews.includes(:movie).each do |review|
              csv << [
                review.movie.title,
                review.rating,
                review.comment,
                review.created_at.strftime("%d/%m/%Y")
              ]
            end
          end
        end
        send_data csv_data, filename: "mes_donnees_cineroom_#{Date.current.strftime('%Y%m%d')}.csv"
      end
    end
  end


  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :bio, :avatar)
  end

  def set_user
    @user = current_user
  end
end
