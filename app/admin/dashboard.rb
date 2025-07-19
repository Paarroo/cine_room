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
                  th "Admins"
                  td User.where(role: :admin).count
                end
                tr do
                  th "Regular Users"
                  td User.where(role: :user).count
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
          panel "Creator Statistics" do
            div class: "attributes_table" do
              table do
                tr do
                  th "Total Creators"
                  td User.creators.count
                end
                tr do
                  th "New Creators (This Month)"
                  td User.creators.where(
                    created_at: Time.current.beginning_of_month..Time.current.end_of_month
                  ).count
                end
                tr do
                  th "Active Creators (Created Movies)"
                  td User.joins(:movies).distinct.count
                end
                tr do
                  th "Creators with Validated Movies"
                  td User.joins(:movies).where(movies: { validation_status: :validated }).distinct.count
                end
              end
            end
          end
        end
      end

      columns do
        column do
          panel "Movie Statistics" do
            div class: "attributes_table" do
              table do
                tr do
                  th "Total Movies"
                  td Movie.count
                end
                tr do
                  th "Validated Movies"
                  td Movie.where(validation_status: :validated).count
                end
                tr do
                  th "Pending Validation"
                  td Movie.where(validation_status: :pending).count
                end
                tr do
                  th "Rejected Movies"
                  td Movie.where(validation_status: :rejected).count
                end
                tr do
                  th "Movies with Events"
                  td Movie.joins(:events).distinct.count
                end
                tr do
                  th "Average Movies per Creator"
                  td begin
                    total_creators = User.creators.count
                    total_movies = Movie.count
                    total_creators > 0 ? (total_movies.to_f / total_creators).round(1) : 0
                  end
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
                  th "Cancelled Participations"
                  td Participation.where(status: :cancelled).count
                end
                tr do
                  th "Total Seats Booked"
                  td Participation.where(status: :confirmed).sum(:seats)
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
          panel "Recent Movies" do
            table_for Movie.includes(:user).order(created_at: :desc).limit(5) do
              column "Title" do |movie|
                movie.title
              end
              column "Creator" do |movie|
                movie.user.full_name if movie.user
              end
              column "Status" do |movie|
                status_tag movie.validation_status.humanize, class: movie.validation_status
              end
              column "Created" do |movie|
                movie.created_at.strftime("%d/%m/%Y")
              end
            end
            div do
              link_to "View all movies", admin_movies_path, class: "button"
            end
          end
        end

        column do
          panel "Recent Events" do
            table_for Event.includes(:movie).order(created_at: :desc).limit(5) do
              column "Title" do |event|
                link_to event.title, admin_event_path(event)
              end
              column "Movie" do |event|
                link_to event.movie.title, admin_movie_path(event.movie) if event.movie
              end
              column "Date" do |event|
                event.event_date.strftime("%d/%m/%Y")
              end
              column "Status" do |event|
                status_tag event.status.humanize, class: event.status
              end
            end
            div do
              link_to "View all events", admin_events_path, class: "button"
            end
          end
        end
      end

      columns do
        column do
          panel "Recent Participations" do
            table_for Participation.includes(:user, :event).order(created_at: :desc).limit(5) do
              column "User" do |participation|
                link_to participation.user.full_name, admin_user_path(participation.user)
              end
              column "Event" do |participation|
                link_to participation.event.title, admin_event_path(participation.event)
              end
              column "Seats" do |participation|
                participation.seats
              end
              column "Status" do |participation|
                status_tag participation.status.humanize, class: participation.status
              end
              column "Revenue" do |participation|
                if participation.status == 'confirmed'
                  number_to_currency(participation.event.price_cents * participation.seats / 100.0)
                else
                  "-"
                end
              end
            end
            div do
              link_to "View all participations", admin_participations_path, class: "button"
            end
          end
        end

        column do
          panel "Recent Reviews" do
            table_for Review.includes(:user, :movie).order(created_at: :desc).limit(5) do
              column "User" do |review|
                link_to review.user.full_name, admin_user_path(review.user)
              end
              column "Movie" do |review|
                link_to review.movie.title, admin_movie_path(review.movie)
              end
              column "Rating" do |review|
                "⭐" * review.rating if review.rating
              end
              column "Comment" do |review|
                truncate(review.comment, length: 50) if review.comment.present?
              end
              column "Date" do |review|
                review.created_at.strftime("%d/%m/%Y")
              end
            end
            div do
              link_to "View all reviews", admin_reviews_path, class: "button"
            end
          end
        end
      end

      panel "Quick Actions" do
        div class: "quick_actions" do
          link_to "Validate Pending Movies", admin_movies_path(scope: :pending), class: "button"
          link_to "View Upcoming Events", admin_events_path(scope: :upcoming), class: "button"
          link_to "Process Pending Participations", admin_participations_path(scope: :pending), class: "button"
          link_to "Export Users", admin_users_path(format: :csv), class: "button"
        end
      end
    end
  end
end
