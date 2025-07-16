ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    div class: "blank_slate_container", id: "dashboard_default_message" do
      columns do
        column do
          panel "Revenue Statistics" do
            div class: "attributes_table" do
              table do
                tr do
                  th "Total Revenue"
                  td number_to_currency(
                    Participation.where(status: :confirmed).joins(:event).sum("events.price_cents") / 100.0
                  )
                end
                tr do
                  th "This Month Revenue"
                  td number_to_currency(
                    Participation.where(
                      status: :confirmed,
                      created_at: Time.current.beginning_of_month..Time.current.end_of_month
                    ).joins(:event).sum("events.price_cents") / 100.0
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
