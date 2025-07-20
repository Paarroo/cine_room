ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "Dashboard"

  controller do
    before_action :authenticate_user!
    before_action :ensure_admin_access!

    private

    def authenticate_user!
      unless user_signed_in?
        redirect_to new_user_session_path, alert: "You must log in"
      end
    end

    def ensure_admin_access!
      unless current_user&.admin?
        redirect_to root_path, alert: "Unauthorized access"
      end
    end

    # Helper methods for calculations
    def calculate_revenue_stats
      confirmed_participations = Participation.where(status: :confirmed).joins(:event)

      {
        total_revenue: confirmed_participations.sum("events.price_cents * participations.seats") / 100.0,
        monthly_revenue: confirmed_participations
          .where(created_at: Time.current.beginning_of_month..Time.current.end_of_month)
          .sum("events.price_cents * participations.seats") / 100.0,
        today_revenue: confirmed_participations
          .where(created_at: Time.current.beginning_of_day..Time.current.end_of_day)
          .sum("events.price_cents * participations.seats") / 100.0
      }
    end

    def calculate_event_stats
      upcoming_count = Event.respond_to?(:statuses) ? (Event.where(status: :upcoming).count rescue Event.count) : Event.count
      completed_count = Event.respond_to?(:statuses) ? (Event.where(status: :completed).count rescue 0) : 0

      # Calculate occupancy rate
      total_capacity = Event.sum(:max_capacity) rescue 0
      total_bookings = Participation.where(status: :confirmed).sum(:seats) rescue 0
      occupancy_rate = total_capacity > 0 ? ((total_bookings.to_f / total_capacity) * 100).round(1) : 0

      {
        total_events: Event.count,
        upcoming_events: upcoming_count,
        completed_events: completed_count,
        occupancy_rate: occupancy_rate
      }
    end

    def calculate_user_stats
      admin_count = User.respond_to?(:roles) ? (User.where(role: :admin).count rescue 0) : 0
      active_users = (User.where(created_at: 1.month.ago..Time.current).count rescue 0)
      new_users = (User.where(
        created_at: Time.current.beginning_of_month..Time.current.end_of_month
      ).count rescue 0)

      {
        total_users: User.count,
        admin_users: admin_count,
        active_users: active_users,
        new_users_this_month: new_users
      }
    end

    def calculate_satisfaction_stats
      average_rating = (Review.average(:rating).to_f.round(1) rescue 0.0)
      total_reviews = (Review.count rescue 0)
      five_star_count = (Review.where(rating: 5).count rescue 0)

      {
        average_rating: average_rating,
        total_reviews: total_reviews,
        five_star_reviews: five_star_count
      }
    end

    def get_recent_activities
      pending_movies_count = begin
        Movie.where(validation_status: :pending).count
      rescue
        0
      end

      pending_participations_count = begin
        Participation.where(status: :pending).count
      rescue
        0
      end

      {
        recent_movies: Movie.includes(:user).order(created_at: :desc).limit(5),
        recent_participations: Participation.includes(:user, :event).order(created_at: :desc).limit(5),
        pending_movies: pending_movies_count,
        pending_participations: pending_participations_count
      }
    end
  end

  content title: "CinéRoom Dashboard" do
    # Add custom CSS for modern design
    div style: "margin-bottom: 2rem;" do
      content_tag :style do
        raw <<~CSS
          .modern-dashboard {
            background: #0a0a0a;
            color: #ffffff;
            font-family: 'Inter', 'Atkinson Hyperlegible', system-ui, sans-serif;
          }

          .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
          }

          .stat-card {
            background: rgba(255, 255, 255, 0.02);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 1rem;
            padding: 1.5rem;
            transition: all 0.3s ease;
          }

          .stat-card:hover {
            transform: translateY(-2px);
            border-color: rgba(245, 158, 11, 0.3);
          }

          .stat-icon {
            width: 3rem;
            height: 3rem;
            border-radius: 0.75rem;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 1rem;
            font-size: 1.25rem;
          }

          .stat-value {
            font-size: 2rem;
            font-weight: bold;
            background: linear-gradient(135deg, #fbbf24, #8b5cf6);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 0.5rem;
          }

          .stat-label {
            color: #9ca3af;
            font-size: 0.875rem;
          }

          .modern-panel {
            background: rgba(255, 255, 255, 0.02);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 1.5rem;
            margin-bottom: 2rem;
          }

          .panel-header {
            padding: 1.5rem 2rem;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            background: rgba(255, 255, 255, 0.02);
          }

          .panel-content {
            padding: 2rem;
          }

          .activity-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 1rem;
            margin-bottom: 0.75rem;
            background: rgba(255, 255, 255, 0.03);
            border-radius: 0.75rem;
            border: 1px solid rgba(255, 255, 255, 0.05);
          }

          .activity-item:hover {
            background: rgba(255, 255, 255, 0.05);
            border-color: rgba(245, 158, 11, 0.2);
          }

          .movie-poster {
            width: 3rem;
            height: 4rem;
            border-radius: 0.5rem;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.75rem;
            font-weight: bold;
            color: white;
            margin-right: 1rem;
          }

          .quick-action-btn {
            background: linear-gradient(135deg, #f59e0b, #d97706);
            color: white;
            padding: 0.75rem 1.5rem;
            border-radius: 0.75rem;
            text-decoration: none;
            font-weight: 600;
            margin-right: 1rem;
            margin-bottom: 0.5rem;
            display: inline-block;
            transition: all 0.3s ease;
          }

          .quick-action-btn:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3);
            color: white;
            text-decoration: none;
          }

          .status-pending {
            background: rgba(245, 158, 11, 0.2);
            color: #fbbf24;
            padding: 0.25rem 0.75rem;
            border-radius: 1rem;
            font-size: 0.75rem;
            font-weight: 600;
          }

          .status-confirmed {
            background: rgba(34, 197, 94, 0.2);
            color: #22c55e;
            padding: 0.25rem 0.75rem;
            border-radius: 1rem;
            font-size: 0.75rem;
            font-weight: 600;
          }

          .welcome-header {
            background: linear-gradient(135deg, rgba(245, 158, 11, 0.1), rgba(139, 92, 246, 0.1));
            border-radius: 1.5rem;
            padding: 2rem;
            margin-bottom: 2rem;
            border: 1px solid rgba(255, 255, 255, 0.1);
          }

          .welcome-title {
            font-size: 2.5rem;
            font-weight: bold;
            margin-bottom: 0.5rem;
            background: linear-gradient(135deg, #fbbf24, #8b5cf6);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
          }

          .welcome-subtitle {
            color: #9ca3af;
            font-size: 1.125rem;
          }
        CSS
      end
    end

    # Modern Dashboard Container
    div class: "modern-dashboard" do
      # Welcome Header
      div class: "welcome-header" do
        h1 class: "welcome-title" do
          "Bonjour #{current_user&.first_name || 'Admin'} !"
        end
        p class: "welcome-subtitle" do
          "Voici un aperçu de votre plateforme CinéRoom"
        end
      end

      # Stats Cards
      div class: "stats-grid" do
        # Revenue Card
        revenue_stats = controller.send(:calculate_revenue_stats)
        div class: "stat-card" do
          div class: "stat-icon", style: "background: rgba(245, 158, 11, 0.1);" do
            content_tag :span, "€", style: "color: #f59e0b; font-weight: bold;"
          end
          div class: "stat-value" do
            number_to_currency(revenue_stats[:monthly_revenue])
          end
          div class: "stat-label" do
            "Revenus ce mois"
          end
        end

        # Active Bookings Card
        div class: "stat-card" do
          div class: "stat-icon", style: "background: rgba(37, 99, 235, 0.1);" do
            content_tag :i, "", class: "fas fa-users", style: "color: #2563eb;"
          end
          div class: "stat-value" do
            Participation.where(status: :confirmed).count.to_s
          end
          div class: "stat-label" do
            "Réservations actives"
          end
        end

        # Occupancy Rate Card
        div class: "stat-card" do
          # Get event stats here
          event_stats = controller.send(:calculate_event_stats)

          div class: "stat-icon", style: "background: rgba(34, 197, 94, 0.1);" do
            content_tag :i, "", class: "fas fa-chart-line", style: "color: #22c55e;"
          end
          div class: "stat-value" do
            "#{event_stats[:occupancy_rate]}%"
          end
          div class: "stat-label" do
            "Taux d'occupation"
          end
        end

        # Satisfaction Card
        div class: "stat-card" do
          # Get satisfaction stats here
          satisfaction_stats = controller.send(:calculate_satisfaction_stats)

          div class: "stat-icon", style: "background: rgba(139, 92, 246, 0.1);" do
            content_tag :i, "", class: "fas fa-heart", style: "color: #8b5cf6;"
          end
          div class: "stat-value" do
            satisfaction_stats[:average_rating].to_s
          end
          div class: "stat-label" do
            "Satisfaction moyenne"
          end
        end
      end

      # Quick Actions Panel
      div class: "modern-panel" do
        div class: "panel-header" do
          h2 "Actions Rapides", style: "font-size: 1.5rem; font-weight: bold; margin: 0;"
        end
        div class: "panel-content" do
          link_to "Gérer les Films", admin_movies_path, class: "quick-action-btn"
          link_to "Gérer les Événements", admin_events_path, class: "quick-action-btn"
          link_to "Gérer les Utilisateurs", admin_users_path, class: "quick-action-btn"
          link_to "Gérer les Participations", admin_participations_path, class: "quick-action-btn"
        end
      end

      # Two Column Layout for Activities
      div style: "display: grid; grid-template-columns: 1fr 1fr; gap: 2rem;" do
        # Recent Events Management
        div class: "modern-panel" do
          div class: "panel-header" do
            h3 "Gestion des Événements", style: "font-size: 1.25rem; font-weight: bold; margin: 0;"
          end
          div class: "panel-content" do
            # Sample events with modern styling
            div class: "activity-item" do
              div style: "display: flex; align-items: center;" do
                div class: "movie-poster", style: "background: linear-gradient(135deg, #ef4444, #ec4899);" do
                  "LS"
                end
                div do
                  div style: "font-weight: 600; margin-bottom: 0.25rem;" do
                    "Le Souffle"
                  end
                  div style: "font-size: 0.875rem; color: #9ca3af;" do
                    "15 Jan • 20h00 • Galerie Marais"
                  end
                end
              end
              div style: "display: flex; align-items: center; gap: 1rem;" do
                span style: "font-size: 0.875rem; font-weight: 500;" do
                  "7/15 places"
                end
                span class: "status-confirmed" do
                  "À venir"
                end
              end
            end

            div class: "activity-item" do
              div style: "display: flex; align-items: center;" do
                div class: "movie-poster", style: "background: linear-gradient(135deg, #3b82f6, #8b5cf6);" do
                  "F"
                end
                div do
                  div style: "font-weight: 600; margin-bottom: 0.25rem;" do
                    "Fragments"
                  end
                  div style: "font-size: 0.875rem; color: #9ca3af;" do
                    "22 Jan • 19h30 • Rooftop République"
                  end
                end
              end
              div style: "display: flex; align-items: center; gap: 1rem;" do
                span style: "font-size: 0.875rem; font-weight: 500;" do
                  "12/15 places"
                end
                span class: "status-pending" do
                  "Bientôt complet"
                end
              end
            end
          end
        end

        # Recent Activity
        div class: "modern-panel" do
          div class: "panel-header" do
            h3 "Activité Récente", style: "font-size: 1.25rem; font-weight: bold; margin: 0;"
          end
          div class: "panel-content" do
            # Get activity data here
            activity_data = controller.send(:get_recent_activities)

            h4 "Derniers Films (5)", style: "font-weight: 600; margin-bottom: 1rem; color: #f59e0b;"

            activity_data[:recent_movies].each do |movie|
              div class: "activity-item" do
                div style: "display: flex; align-items: center;" do
                  div class: "movie-poster", style: "background: linear-gradient(135deg, #10b981, #059669);" do
                    movie.title.first(2).upcase rescue "??"
                  end
                  div do
                    div style: "font-weight: 600; margin-bottom: 0.25rem;" do
                      link_to movie.title, admin_movie_path(movie), style: "color: white; text-decoration: none;"
                    end
                    div style: "font-size: 0.875rem; color: #9ca3af;" do
                      movie.user&.full_name || "Créateur inconnu"
                    end
                  end
                end
                div do
                  validation_status = movie.validation_status rescue "unknown"
                  status_class = case validation_status
                  when "validated" then "status-confirmed"
                  when "pending" then "status-pending"
                  else "status-pending"
                  end
                  span class: status_class do
                    validation_status.humanize rescue "Inconnu"
                  end
                end
              end
            end

            br

            h4 "Dernières Participations (5)", style: "font-weight: 600; margin-bottom: 1rem; margin-top: 1.5rem; color: #8b5cf6;"

            activity_data[:recent_participations].each do |participation|
              div class: "activity-item" do
                div style: "display: flex; align-items: center;" do
                  div class: "movie-poster", style: "background: linear-gradient(135deg, #f59e0b, #d97706);" do
                    (participation.user&.full_name&.split&.map(&:first)&.join || "??").upcase
                  end
                  div do
                    div style: "font-weight: 600; margin-bottom: 0.25rem;" do
                      participation.user&.full_name || "Utilisateur inconnu"
                    end
                    div style: "font-size: 0.875rem; color: #9ca3af;" do
                      participation.event&.title || "Événement inconnu"
                    end
                  end
                end
                div do
                  status = participation.status rescue "unknown"
                  status_class = case status
                  when "confirmed" then "status-confirmed"
                  when "pending" then "status-pending"
                  else "status-pending"
                  end
                  span class: status_class do
                    status.humanize rescue "Inconnu"
                  end
                end
              end
            end
          end
        end
      end

      # Summary Statistics
      div class: "modern-panel" do
        div class: "panel-header" do
          h3 "Statistiques Détaillées", style: "font-size: 1.25rem; font-weight: bold; margin: 0;"
        end
        div class: "panel-content" do
          # Get data here for stats
          activity_data = controller.send(:get_recent_activities)
          user_stats = controller.send(:calculate_user_stats)

          div style: "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 2rem;" do
            div style: "text-align: center;" do
              div style: "font-size: 2rem; font-weight: bold; color: #3b82f6; margin-bottom: 0.5rem;" do
                user_stats[:total_users].to_s
              end
              div style: "color: #9ca3af;" do
                "Utilisateurs Total"
              end
            end

            div style: "text-align: center;" do
              # Get event stats for total events
              event_stats = controller.send(:calculate_event_stats)
              div style: "font-size: 2rem; font-weight: bold; color: #22c55e; margin-bottom: 0.5rem;" do
                event_stats[:total_events].to_s
              end
              div style: "color: #9ca3af;" do
                "Événements Total"
              end
            end

            div style: "text-align: center;" do
              div style: "font-size: 2rem; font-weight: bold; color: #f59e0b; margin-bottom: 0.5rem;" do
                activity_data[:pending_movies].to_s
              end
              div style: "color: #9ca3af;" do
                "Films en Attente"
              end
            end

            div style: "text-align: center;" do
              # Get satisfaction stats for total reviews
              satisfaction_stats = controller.send(:calculate_satisfaction_stats)
              div style: "font-size: 2rem; font-weight: bold; color: #8b5cf6; margin-bottom: 0.5rem;" do
                satisfaction_stats[:total_reviews].to_s
              end
              div style: "color: #9ca3af;" do
                "Avis Total"
              end
            end
          end
        end
      end
    end
  end
end
