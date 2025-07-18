ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    div class: "blank_slate_container", id: "dashboard_default_message" do

      # Revenue and Financial Statistics
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
                tr do
                  th "Average Revenue per Event"
                  td number_to_currency(
                    Event.joins(:participations)
                         .where(participations: { status: :confirmed })
                         .group(:id)
                         .sum("events.price_cents * participations.seats")
                         .values.sum / Event.joins(:participations).distinct.count.to_f / 100.0
                  )
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
                tr do
                  th "Sold Out Events"
                  td Event.where(status: :sold_out).count
                end
                tr do
                  th "Average Capacity"
                  td "#{Event.average(:max_capacity).to_i} seats"
                end
                tr do
                  th "Average Occupancy Rate"
                  td begin
                    total_capacity = Event.sum(:max_capacity)
                    total_bookings = Participation.where(status: :confirmed).sum(:seats)
                    if total_capacity > 0
                      "#{((total_bookings.to_f / total_capacity) * 100).round(1)}%"
                    else
                      "0%"
                    end
                  end
                end
              end
            end
          end
        end
      end
