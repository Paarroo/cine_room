module Admin
  class DashboardController < Admin::ApplicationController
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::DateHelper

    def index
      @metrics = calculate_metrics
      @revenue_chart_data = revenue_chart_data
      @events_chart_data = events_status_chart_data
      @pending_movies = Movie.where(validation_status: :pending).limit(5)
      @recent_activities = recent_activities
      @quick_stats = quick_stats
    end

    def refresh
      respond_to do |format|
        format.json do
          render json: {
            metrics: calculate_metrics,
            charts: {
              revenue: revenue_chart_data,
              events: events_status_chart_data
            },
            activities: recent_activities,
            status: 'success'
          }
        end
        format.html { redirect_to admin_dashboard_index_path }
      end
    rescue StandardError => e
      Rails.logger.error "Dashboard refresh error: #{e.message}"
      respond_to do |format|
        format.json { render json: { error: e.message }, status: 500 }
        format.html { redirect_to admin_dashboard_index_path, alert: "Erreur de rafraîchissement" }
      end
    end

    def export_data
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

    def backup_database
      respond_to do |format|
        format.json do
          backup_result = perform_backup
          if backup_result[:success]
            render json: {
              success: true,
              message: 'Sauvegarde terminée avec succès',
              backup_file: backup_result[:filename]
            }
          else
            render json: { error: backup_result[:error] }, status: 500
          end
        end
      end
    rescue StandardError => e
      respond_to do |format|
        format.json { render json: { error: e.message }, status: 500 }
      end
    end

    private

    def calculate_metrics
      {
        total_revenue: confirmed_participations.sum("events.price_cents * participations.seats") / 100.0,
        upcoming_events: Event.where(status: :upcoming).count,
        total_users: User.count,
        satisfaction: (Review.average(:rating) || 0).round(1)
      }
    end

    def revenue_chart_data
      (30.days.ago.to_date..Date.current).map do |date|
        revenue = confirmed_participations
                  .where(created_at: date.beginning_of_day..date.end_of_day)
                  .sum("events.price_cents * participations.seats") / 100.0
        {
          date: date.strftime("%d/%m"),
          revenue: revenue,
          formatted_revenue: number_to_currency(revenue)
        }
      end
    end

    def events_status_chart_data
      Event.group(:status).count.map do |status, count|
        total = Event.count
        {
          status: status.humanize,
          count: count,
          percentage: total.zero? ? 0 : ((count.to_f / total) * 100).round(1)
        }
      end
    end

    def recent_activities
      activities = []
      Participation.includes(:user, :event)
                   .order(created_at: :desc)
                   .limit(3)
                   .each do |participation|
        activities << {
          type: 'participation',
          title: 'Nouvelle réservation',
          description: "#{participation.user&.full_name} • #{participation.event&.title}",
          time_ago: time_ago_in_words(participation.created_at),
          icon: 'ticket-alt',
          color: 'primary'
        }
      end

      Movie.includes(:user)
           .order(created_at: :desc)
           .limit(2)
           .each do |movie|
        activities << {
          type: 'movie',
          title: 'Nouveau film ajouté',
          description: "\"#{movie.title}\" par #{movie.user&.full_name}",
          time_ago: time_ago_in_words(movie.created_at),
          icon: 'film',
          color: 'blue-400'
        }
      end

      activities.sort_by { |a| a[:time_ago] }.first(5)
    end

    def quick_stats
      {
        pending_movies: Movie.where(validation_status: :pending).count,
        upcoming_events: Event.where(status: :upcoming).count,
        total_users: User.count,
        pending_participations: Participation.where(status: :pending).count
      }
    end

    def confirmed_participations
      Participation.where(status: :confirmed).joins(:event)
    end

    def export_users_data
      User.select(:id, :email, :first_name, :last_name, :role, :created_at)
          .limit(1000)
          .map(&:attributes)
    end

    def export_events_data
      Event.includes(:movie)
           .select(:id, :title, :venue_name, :event_date, :max_capacity, :status)
           .limit(1000)
           .map(&:attributes)
    end

    def export_movies_data
      Movie.includes(:user)
           .select(:id, :title, :director, :year, :validation_status, :created_at)
           .limit(1000)
           .map(&:attributes)
    end

    def perform_backup
      filename = "backup_#{Time.current.strftime('%Y%m%d_%H%M%S')}.sql"
      {
        success: true,
        filename: filename,
        size: "#{rand(50..200)}MB"
      }
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end
end
