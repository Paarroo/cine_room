ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "Dashboard"
  content title: "Dashboard" do
      render partial: 'admin/dashboard/index', layout: false
    end

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

    # Calculate comprehensive revenue statistics
    def calculate_revenue_stats
      confirmed_participations = Participation.where(status: :confirmed).joins(:event)
      current_month = Time.current.beginning_of_month..Time.current.end_of_month
      today = Time.current.beginning_of_day..Time.current.end_of_day

      {
        total_revenue: confirmed_participations.sum("events.price_cents * participations.seats") / 100.0,
        monthly_revenue: confirmed_participations
          .where(created_at: current_month)
          .sum("events.price_cents * participations.seats") / 100.0,
        today_revenue: confirmed_participations
          .where(created_at: today)
          .sum("events.price_cents * participations.seats") / 100.0
      }
    end

    def calculate_event_stats
      {
        total_events: Event.count,
        upcoming_events: Event.where(status: :upcoming).count,
        completed_events: Event.where(status: :completed).count,
        sold_out_events: Event.where(status: :sold_out).count
      }
    end

    def calculate_user_stats
      current_month = Time.current.beginning_of_month..Time.current.end_of_month

      {
        total_users: User.count,
        new_users_this_month: User.where(created_at: current_month).count,
        active_participants: User.joins(:participations)
                                .where(participations: { status: :confirmed })
                                .distinct.count
      }
    end
  end

  # Content uses ActiveAdmin default layout
  content title: "CinéRoom Dashboard" do
    # Dashboard Header
    div class: "dashboard-header" do
      div class: "welcome-section", style: "background: linear-gradient(135deg, rgba(245, 158, 11, 0.1), rgba(139, 92, 246, 0.1)); border-radius: 1rem; padding: 2rem; margin-bottom: 2rem; border: 1px solid rgba(255, 255, 255, 0.1);" do
        h1 "Bonjour #{current_user&.first_name || 'Admin'} !", style: "font-size: 2.5rem; font-weight: bold; margin-bottom: 0.5rem; background: linear-gradient(135deg, #fbbf24, #8b5cf6); -webkit-background-clip: text; -webkit-text-fill-color: transparent;"
        p "Tableau de bord CinéRoom - #{Date.current.strftime('%d %B %Y')}", style: "color: #9ca3af; font-size: 1.125rem;"

        div style: "margin-top: 1.5rem;" do
          # Fixed: Using correct ActiveAdmin routes
          link_to "Nouveau Film", admin_movies_path, class: "button", style: "margin-right: 1rem; background: linear-gradient(135deg, #f59e0b, #d97706); color: white; padding: 0.75rem 1.5rem; border-radius: 0.75rem; text-decoration: none;"
          link_to "Nouvel Événement", admin_events_path, class: "button", style: "background: rgba(255, 255, 255, 0.1); color: white; padding: 0.75rem 1.5rem; border-radius: 0.75rem; text-decoration: none;"
        end
      end
    end

    # Key Metrics
    div class: "metrics-section" do
      h2 "Métriques Clés", style: "font-size: 1.5rem; font-weight: bold; margin-bottom: 1.5rem; color: #f59e0b;"

      div style: "display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1.5rem; margin-bottom: 2rem;" do
        # Revenue Metric
        div class: "metric-card", style: "background: rgba(255, 255, 255, 0.02); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 1rem; padding: 1.5rem; transition: all 0.3s ease;" do
          div style: "display: flex; align-items: center; justify-content: between; margin-bottom: 1rem;" do
            div style: "width: 3rem; height: 3rem; background: rgba(245, 158, 11, 0.1); border-radius: 0.75rem; display: flex; align-items: center; justify-content: center;" do
              content_tag :i, "", class: "fas fa-euro-sign", style: "color: #f59e0b; font-size: 1.25rem;"
            end
          end

          revenue_stats = controller.send(:calculate_revenue_stats)
          div number_to_currency(revenue_stats[:total_revenue]), style: "font-size: 2rem; font-weight: bold; background: linear-gradient(135deg, #fbbf24, #8b5cf6); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 0.5rem;"
          div "Revenus Total", style: "color: #9ca3af; font-size: 0.875rem;"
          div "#{number_to_currency(revenue_stats[:monthly_revenue])} ce mois", style: "color: #6b7280; font-size: 0.75rem; margin-top: 0.25rem;"
        end

        # Active Events Metric
        div class: "metric-card", style: "background: rgba(255, 255, 255, 0.02); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 1rem; padding: 1.5rem;" do
          div style: "display: flex; align-items: center; margin-bottom: 1rem;" do
            div style: "width: 3rem; height: 3rem; background: rgba(37, 99, 235, 0.1); border-radius: 0.75rem; display: flex; align-items: center; justify-content: center;" do
              content_tag :i, "", class: "fas fa-calendar-alt", style: "color: #2563eb; font-size: 1.25rem;"
            end
          end

          event_stats = controller.send(:calculate_event_stats)
          div event_stats[:upcoming_events].to_s, style: "font-size: 2rem; font-weight: bold; color: #2563eb; margin-bottom: 0.5rem;"
          div "Événements Actifs", style: "color: #9ca3af; font-size: 0.875rem;"
          div "#{event_stats[:sold_out_events]} complets", style: "color: #6b7280; font-size: 0.75rem; margin-top: 0.25rem;"
        end

        # Users Metric
        div class: "metric-card", style: "background: rgba(255, 255, 255, 0.02); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 1rem; padding: 1.5rem;" do
          div style: "display: flex; align-items: center; margin-bottom: 1rem;" do
            div style: "width: 3rem; height: 3rem; background: rgba(34, 197, 94, 0.1); border-radius: 0.75rem; display: flex; align-items: center; justify-content: center;" do
              content_tag :i, "", class: "fas fa-users", style: "color: #22c55e; font-size: 1.25rem;"
            end
          end

          user_stats = controller.send(:calculate_user_stats)
          div user_stats[:total_users].to_s, style: "font-size: 2rem; font-weight: bold; color: #22c55e; margin-bottom: 0.5rem;"
          div "Utilisateurs Total", style: "color: #9ca3af; font-size: 0.875rem;"
          div "#{user_stats[:active_participants]} actifs", style: "color: #6b7280; font-size: 0.75rem; margin-top: 0.25rem;"
        end

        # Satisfaction Metric
        div class: "metric-card", style: "background: rgba(255, 255, 255, 0.02); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 1rem; padding: 1.5rem;" do
          div style: "display: flex; align-items: center; margin-bottom: 1rem;" do
            div style: "width: 3rem; height: 3rem; background: rgba(245, 158, 11, 0.1); border-radius: 0.75rem; display: flex; align-items: center; justify-content: center;" do
              content_tag :i, "", class: "fas fa-star", style: "color: #f59e0b; font-size: 1.25rem;"
            end
          end

          avg_rating = Review.average(:rating) || 0
          div "#{avg_rating.round(1)}/5", style: "font-size: 2rem; font-weight: bold; color: #f59e0b; margin-bottom: 0.5rem;"
          div "Satisfaction", style: "color: #9ca3af; font-size: 0.875rem;"
          div "#{Review.count} avis", style: "color: #6b7280; font-size: 0.75rem; margin-top: 0.25rem;"
        end
      end
    end

    # Management Section
    div class: "management-section" do
      div style: "display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; margin-bottom: 2rem;" do
        # Pending Movies
        div class: "panel" do
          h3 "Films en Attente de Validation", style: "color: #f59e0b; margin-bottom: 1rem;"

          pending_movies = Movie.where(validation_status: :pending).limit(5)
          if pending_movies.any?
            div style: "space-y: 0.75rem;" do
              pending_movies.each do |movie|
                div style: "display: flex; align-items: center; justify-content: space-between; padding: 1rem; background: rgba(255, 255, 255, 0.05); border-radius: 0.75rem; margin-bottom: 0.75rem;" do
                  div do
                    div movie.title, style: "font-weight: 600; color: white; margin-bottom: 0.25rem;"
                    div "#{movie.director} • #{movie.year}", style: "font-size: 0.875rem; color: #9ca3af;"
                    div "Par #{movie.user&.full_name || 'Créateur inconnu'}", style: "font-size: 0.75rem; color: #6b7280;"
                  end

                  div style: "display: flex; gap: 0.5rem;" do
                    # Fixed: Using correct ActiveAdmin route
                    link_to "Voir", admin_movie_path(movie), class: "button", style: "padding: 0.25rem 0.75rem; background: rgba(37, 99, 235, 0.2); color: #3b82f6; border-radius: 0.5rem; text-decoration: none; font-size: 0.875rem;"
                  end
                end
              end
            end

            div style: "margin-top: 1rem; text-align: center;" do
              # Fixed: Using correct ActiveAdmin route with filter
              link_to "Voir tous les films en attente", admin_movies_path + "?q[validation_status_eq]=pending", style: "color: #f59e0b; text-decoration: none;"
            end
          else
            div style: "text-align: center; padding: 2rem; color: #9ca3af;" do
              content_tag :i, "", class: "fas fa-check-circle", style: "font-size: 3rem; color: #22c55e; margin-bottom: 1rem; display: block;"
              div "Aucun film en attente de validation"
            end
          end
        end

        # Recent Activity
        div class: "panel" do
          h3 "Activité Récente", style: "color: #2563eb; margin-bottom: 1rem;"

          div style: "space-y: 1rem;" do
            # Recent Participations
            Participation.includes(:user, :event).order(created_at: :desc).limit(3).each do |participation|
              div style: "display: flex; align-items: center; gap: 1rem; padding: 0.75rem; background: rgba(255, 255, 255, 0.03); border-radius: 0.5rem; margin-bottom: 0.75rem;" do
                div style: "width: 2.5rem; height: 2.5rem; background: rgba(245, 158, 11, 0.2); border-radius: 0.5rem; display: flex; align-items: center; justify-content: center;" do
                  content_tag :i, "", class: "fas fa-ticket-alt", style: "color: #f59e0b; font-size: 0.875rem;"
                end

                div style: "flex: 1;" do
                  div "Nouvelle réservation", style: "font-size: 0.875rem; font-weight: 500; color: white; margin-bottom: 0.25rem;"
                  div "#{participation.user&.full_name || 'Utilisateur'} • #{participation.event&.title || 'Événement'}", style: "font-size: 0.75rem; color: #9ca3af;"
                end

                div time_ago_in_words(participation.created_at), style: "font-size: 0.75rem; color: #6b7280;"
              end
            end

            # Recent Movies
            Movie.includes(:user).order(created_at: :desc).limit(2).each do |movie|
              div style: "display: flex; align-items: center; gap: 1rem; padding: 0.75rem; background: rgba(255, 255, 255, 0.03); border-radius: 0.5rem; margin-bottom: 0.75rem;" do
                div style: "width: 2.5rem; height: 2.5rem; background: rgba(37, 99, 235, 0.2); border-radius: 0.5rem; display: flex; align-items: center; justify-content: center;" do
                  content_tag :i, "", class: "fas fa-film", style: "color: #3b82f6; font-size: 0.875rem;"
                end

                div style: "flex: 1;" do
                  div "Nouveau film ajouté", style: "font-size: 0.875rem; font-weight: 500; color: white; margin-bottom: 0.25rem;"
                  div "\"#{movie.title}\" par #{movie.user&.full_name || 'Créateur'}", style: "font-size: 0.75rem; color: #9ca3af;"
                end

                div time_ago_in_words(movie.created_at), style: "font-size: 0.75rem; color: #6b7280;"
              end
            end
          end
        end
      end
    end

    # Quick Actions
    div class: "quick-actions" do
      h3 "Actions Rapides", style: "color: #f59e0b; margin-bottom: 1.5rem; font-size: 1.25rem;"

      div style: "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-bottom: 2rem;" do
        # Fixed: Using correct ActiveAdmin routes
        link_to admin_movies_path, style: "padding: 1rem; background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 1rem; text-decoration: none; color: white; transition: all 0.3s ease; display: block;" do
          div style: "display: flex; align-items: center; gap: 0.75rem;" do
            div style: "width: 3rem; height: 3rem; background: rgba(245, 158, 11, 0.2); border-radius: 0.75rem; display: flex; align-items: center; justify-content: center;" do
              content_tag :i, "", class: "fas fa-film", style: "color: #f59e0b;"
            end
            div do
              div "Gérer Films", style: "font-weight: 600; margin-bottom: 0.25rem;"
              div "#{Movie.where(validation_status: :pending).count} en attente", style: "font-size: 0.875rem; color: #9ca3af;"
            end
          end
        end

        link_to admin_events_path, style: "padding: 1rem; background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 1rem; text-decoration: none; color: white; transition: all 0.3s ease; display: block;" do
          div style: "display: flex; align-items: center; gap: 0.75rem;" do
            div style: "width: 3rem; height: 3rem; background: rgba(37, 99, 235, 0.2); border-radius: 0.75rem; display: flex; align-items: center; justify-content: center;" do
              content_tag :i, "", class: "fas fa-calendar-alt", style: "color: #2563eb;"
            end
            div do
              div "Événements", style: "font-weight: 600; margin-bottom: 0.25rem;"
              div "#{Event.where(status: :upcoming).count} à venir", style: "font-size: 0.875rem; color: #9ca3af;"
            end
          end
        end

        link_to admin_users_path, style: "padding: 1rem; background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 1rem; text-decoration: none; color: white; transition: all 0.3s ease; display: block;" do
          div style: "display: flex; align-items: center; gap: 0.75rem;" do
            div style: "width: 3rem; height: 3rem; background: rgba(34, 197, 94, 0.2); border-radius: 0.75rem; display: flex; align-items: center; justify-content: center;" do
              content_tag :i, "", class: "fas fa-users", style: "color: #22c55e;"
            end
            div do
              div "Utilisateurs", style: "font-weight: 600; margin-bottom: 0.25rem;"
              div "#{User.count} total", style: "font-size: 0.875rem; color: #9ca3af;"
            end
          end
        end

        link_to admin_participations_path, style: "padding: 1rem; background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 1rem; text-decoration: none; color: white; transition: all 0.3s ease; display: block;" do
          div style: "display: flex; align-items: center; gap: 0.75rem;" do
            div style: "width: 3rem; height: 3rem; background: rgba(245, 158, 11, 0.2); border-radius: 0.75rem; display: flex; align-items: center; justify-content: center;" do
              content_tag :i, "", class: "fas fa-ticket-alt", style: "color: #f59e0b;"
            end
            div do
              div "Réservations", style: "font-weight: 600; margin-bottom: 0.25rem;"
              div "#{Participation.where(status: :pending).count} en attente", style: "font-size: 0.875rem; color: #9ca3af;"
            end
          end
        end
      end
    end

    # System Status
    div class: "system-status" do
      div style: "background: rgba(255, 255, 255, 0.02); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 1rem; padding: 1.5rem;" do
        div style: "display: flex; align-items: center; justify-content: space-between; margin-bottom: 1rem;" do
          div style: "display: flex; align-items: center; gap: 1.5rem;" do
            div style: "display: flex; align-items: center; gap: 0.5rem;" do
              div style: "width: 0.75rem; height: 0.75rem; background: #22c55e; border-radius: 50%; animation: pulse 2s infinite;"
              span "Système opérationnel", style: "color: white; font-weight: 500;"
            end

            div style: "display: flex; align-items: center; gap: 0.5rem;" do
              div style: "width: 0.75rem; height: 0.75rem; background: #2563eb; border-radius: 50%;"
              span "Base de données: OK", style: "color: #9ca3af;"
            end
          end

          div "Dernière mise à jour: #{Time.current.strftime('%H:%M')}", style: "color: #6b7280; font-size: 0.875rem;"
        end

        # Performance Indicators
        div style: "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem;" do
          total_capacity = Event.sum(:max_capacity)
          total_bookings = Participation.where(status: :confirmed).sum(:seats)
          occupancy_rate = total_capacity > 0 ? ((total_bookings.to_f / total_capacity) * 100).round(1) : 0

          div style: "background: rgba(255, 255, 255, 0.03); border-radius: 0.75rem; padding: 1rem;" do
            div style: "display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.5rem;" do
              span "Taux d'occupation", style: "color: #9ca3af;"
              span "#{occupancy_rate}%", style: "color: #22c55e; font-weight: bold;"
            end
            div style: "width: 100%; background: rgba(255, 255, 255, 0.1); border-radius: 0.25rem; height: 0.5rem;" do
              div style: "background: linear-gradient(90deg, #22c55e, #16a34a); height: 100%; border-radius: 0.25rem; width: #{occupancy_rate}%; transition: width 0.5s ease;"
            end
          end

          confirmed_count = Participation.where(status: :confirmed).count
          total_count = Participation.count
          conversion_rate = total_count > 0 ? ((confirmed_count.to_f / total_count) * 100).round(1) : 0

          div style: "background: rgba(255, 255, 255, 0.03); border-radius: 0.75rem; padding: 1rem;" do
            div style: "display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.5rem;" do
              span "Taux de conversion", style: "color: #9ca3af;"
              span "#{conversion_rate}%", style: "color: #2563eb; font-weight: bold;"
            end
            div style: "width: 100%; background: rgba(255, 255, 255, 0.1); border-radius: 0.25rem; height: 0.5rem;" do
              div style: "background: linear-gradient(90deg, #2563eb, #1d4ed8); height: 100%; border-radius: 0.25rem; width: #{conversion_rate}%; transition: width 0.5s ease;"
            end
          end
        end
      end
    end
  end
end
