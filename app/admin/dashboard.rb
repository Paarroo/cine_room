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
                  th "Sold Out Events"
                  td Event.where(status: :sold_out).count
                end
                tr do
                  th "Average Capacity"
                  td "#{Event.average(:max_capacity).to_i} seats"
                end
              end
            end
          end
        end
      end

      columns do
        column do
          panel "User Statistics" do
            div class: "attributes_table" do
              table do
                tr do
                  th "Total Users"
                  td User.count
                end
                tr do
                  th "New Users (This Month)"
                  td User.where(
                    created_at: Time.current.beginning_of_month..Time.current.end_of_month
                  ).count
                end
                tr do
                  th "Active Participants"
                  td User.joins(:participations).where(participations: { status: :confirmed }).distinct.count
                end
              end
            end
          end
        end

        column do
          panel "Participation Statistics" do
            div class: "attributes_table" do
              table do
                tr do
                  th "Total Participations"
                  td Participation.count
                end
                tr do
                  th "Confirmed Participations"
                  td Participation.where(status: :confirmed).count
                end
                tr do
                  th "Pending Participations"
                  td Participation.where(status: :pending).count
                end
                tr do
                  th "Average Seats per Booking"
                  td Participation.average(:seats).to_f.round(1)
                end
              end
            end
          end
        end
      end

      columns do
        column do
          panel "Recent Events" do
            table_for Event.includes(:movie).order(created_at: :desc).limit(5) do
              column "Title" do |event|
                link_to event.title, admin_event_path(event)
              end
              column "Movie", :movie
              column "Date", :event_date
              column "Status" do |event|
                status_tag event.status.humanize, class: event.status
              end
            end
          end
        end

        column do
          panel "Recent Participations" do
            table_for Participation.includes(:user, :event).order(created_at: :desc).limit(5) do
              column "User" do |participation|
                link_to participation.user.email, admin_user_path(participation.user)
              end
              column "Event", :event
              column "Seats", :seats
              column "Status" do |participation|
                status_tag participation.status.humanize, class: participation.status
              end
            end
          end
        end
      end
    end
  end
end
