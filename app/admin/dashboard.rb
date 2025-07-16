# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel "Statistiques Générales" do
          table_for [
            { label: "Utilisateurs Total", value: User.count, icon: "👥" },
            { label: "Films Validés", value: Movie.where(validation_status: 'validated').count, icon: "🎬" },
            { label: "Événements Actifs", value: Event.where(status: 'upcoming').count, icon: "📅" },
            { label: "Réservations Ce Mois", value: Participation.where(created_at: 1.month.ago..Time.current).count, icon: "🎫" }
          ] do
            column("") { |item| item[:icon] }
            column("Métrique") { |item| item[:label] }
            column("Valeur") { |item| content_tag :strong, item[:value] }
          end
        end
      end

      column do
        panel "Revenus & Conversion" do
          total_revenue = Participation.joins(:event)
                           .where(status: 'confirmed')
                           .sum('events.price_cents') / 100.0

          monthly_revenue = Participation.joins(:event)
                             .where(status: 'confirmed', created_at: 1.month.ago..Time.current)
                             .sum('events.price_cents') / 100.0

          table_for [
            { label: "Revenus Total", value: "#{total_revenue}€", icon: "💰" },
            { label: "Revenus Ce Mois", value: "#{monthly_revenue}€", icon: "📊" },
            { label: "Taux Occupation Moyen", value: "#{Event.joins(:participations).group('events.id').average('participations.seats * 100.0 / events.max_capacity').values.sum / Event.joins(:participations).count rescue 0}%", icon: "📈" },
            { label: "Note Moyenne", value: "#{Review.average(:rating).to_f.round(1)}/5", icon: "⭐" }
          ] do
            column("") { |item| item[:icon] }
            column("Métrique") { |item| item[:label] }
            column("Valeur") { |item| content_tag :strong, item[:value] }
          end
        end
      end
    end

    columns do
      column do
        panel "Événements Récents" do
          table_for Event.includes(:movie).order(created_at: :desc).limit(5) do
            column("Film") { |event| link_to event.movie.title, admin_movie_path(event.movie) }
            column("Date") { |event| event.event_date.strftime("%d/%m/%Y") }
            column("Lieu") { |event| event.venue_name }
            column("Places") { |event| "#{event.participations.sum(:seats)}/#{event.max_capacity}" }
            column("Statut") { |event| status_tag(event.status) }
          end
        end
      end
