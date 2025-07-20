ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "Dashboard"

  # Contrôleur personnalisé pour gérer l'authentification
  controller do
    before_action :authenticate_user!
    before_action :ensure_admin_access!

    private

    def ensure_admin_access!
      unless current_user&.admin?
        redirect_to root_path, alert: "Accès non autorisé"
        return
      end
    end
  end

  content title: "Dashboard" do
    # Vérification de sécurité supplémentaire
    if current_user&.admin?
      div class: "blank_slate_container", id: "dashboard_default_message" do
        columns do
          column do
            panel "Revenue Statistics" do
              div class: "attributes_table" do
                table do
                  tr do
                    th "Total Revenue"
                    td number_to_currency(
                      Participation.where(status: :confirmed).joins(:event).sum("events.price_cents * participations.seats") / 100.0
                    )
                  end
                  tr do
                    th "This Month Revenue"
                    td number_to_currency(
                      Participation.where(
                        status: :confirmed,
                        created_at: Time.current.beginning_of_month..Time.current.end_of_month
                      ).joins(:event).sum("events.price_cents * participations.seats") / 100.0
                    )
                  end
                  tr do
                    th "Average Event Price"
                    td number_to_currency(Event.average(:price_cents).to_f / 100.0)
                  end
                end
              end
            end
          end

          column do
            panel "Event Statistics" do
              div class: "attributes_table" do
                table do
                  tr do
                    th "Total Events"
                    td Event.count
                  end
                  tr do
                    th "Upcoming Events"
                    td Event.where(status: :upcoming).count
                  end
                  tr do
                    th "Completed Events"
                    td Event.where(status: :completed).count
                  end
                end
              end
            end
          end
        end

        panel "Quick Actions" do
          div class: "quick_actions" do
            link_to "Validate Pending Movies", admin_movies_path, class: "button"
            link_to "View Upcoming Events", admin_events_path, class: "button"
            link_to "Process Pending Participations", admin_participations_path, class: "button"
          end
        end
      end
    else
      div do
        h2 "Accès non autorisé"
        p "Vous devez être administrateur pour accéder à cette page."
      end
    end
  end
end
