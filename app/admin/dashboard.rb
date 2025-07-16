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
