ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "Dashboard"

  # Controller methods for dashboard logic
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
        average_event_price: Event.average(:price_cents).to_f / 100.0
      }
    end

    # Fixed syntax error - proper hash closing and error handling
    def calculate_event_stats
      {
        total_events: Event.count,
        upcoming_events: safe_count { Event.where(status: :upcoming).count },
        completed_events: safe_count { Event.where(status: :completed).count }
      }
    end

    def calculate_user_stats
      {
        total_users: User.count,
        admin_users: safe_count { User.where(role: :admin).count },
        regular_users: safe_count { User.where(role: :user).count }
      }
    end

    def calculate_movie_stats
      {
        total_movies: Movie.count,
        validated_movies: safe_count { Movie.where(validation_status: :validated).count },
        pending_movies: safe_count { Movie.where(validation_status: :pending).count }
      }
    end

    # Helper method for safe counting with error handling
    def safe_count(default_value = 0)
      begin
        yield
      rescue StandardError => e
        Rails.logger.warn "Count query failed: #{e.message}"
        default_value
      end
    end
  end

  # Dashboard content
  content title: "CinéRoom Dashboard" do
    # Revenue stats section
    columns do
      column do
        panel "Revenue Statistics" do
          revenue_stats = controller.send(:calculate_revenue_stats)
          div class: "attributes_table" do
            table do
              tr do
                th "Total Revenue"
                td number_to_currency(revenue_stats[:total_revenue])
              end
              tr do
                th "Monthly Revenue"
                td number_to_currency(revenue_stats[:monthly_revenue])
              end
              tr do
                th "Average Event Price"
                td number_to_currency(revenue_stats[:average_event_price])
              end
            end
          end
        end
      end

      column do
        panel "Event Statistics" do
          event_stats = controller.send(:calculate_event_stats)
          div class: "attributes_table" do
            table do
              tr do
                th "Total Events"
                td event_stats[:total_events]
              end
              tr do
                th "Upcoming Events"
                td event_stats[:upcoming_events]
              end
              tr do
                th "Completed Events"
                td event_stats[:completed_events]
              end
            end
          end
        end
      end
    end

    # User and movie stats section
    columns do
      column do
        panel "User Statistics" do
          user_stats = controller.send(:calculate_user_stats)
          div class: "attributes_table" do
            table do
              tr do
                th "Total Users"
                td user_stats[:total_users]
              end
              tr do
                th "Administrators"
                td user_stats[:admin_users]
              end
              tr do
                th "Regular Users"
                td user_stats[:regular_users]
              end
            end
          end
        end
      end

      column do
        panel "Movie Statistics" do
          movie_stats = controller.send(:calculate_movie_stats)
          div class: "attributes_table" do
            table do
              tr do
                th "Total Movies"
                td movie_stats[:total_movies]
              end
              tr do
                th "Validated Movies"
                td movie_stats[:validated_movies]
              end
              tr do
                th "Pending Movies"
                td movie_stats[:pending_movies]
              end
            end
          end
        end
      end
    end

    # Quick actions panel
    panel "Quick Actions" do
      div class: "quick_actions", style: "padding: 20px;" do
        link_to "Manage Movies", admin_movies_path, class: "button", style: "margin-right: 10px;"
        link_to "Manage Events", admin_events_path, class: "button", style: "margin-right: 10px;"
        link_to "Manage Users", admin_users_path, class: "button", style: "margin-right: 10px;"
        link_to "Manage Participations", admin_participations_path, class: "button"
      end
    end

    # Recent activity panel
    panel "Recent Activity" do
      # Recent movies
      h4 "Recent Movies (Last 5)"
      table_for Movie.includes(:user).order(created_at: :desc).limit(5) do
        column :title do |movie|
          link_to movie.title, admin_movie_path(movie)
        end
        column :user do |movie|
          movie.user&.full_name || "Unknown"
        end
        column :validation_status do |movie|
          status_tag movie.validation_status.humanize, class: movie.validation_status
        end
        column :created_at do |movie|
          movie.created_at.strftime("%d/%m/%Y")
        end
      end

      br

      # Recent participations
      h4 "Recent Participations (Last 5)"
      table_for Participation.includes(:user, :event).order(created_at: :desc).limit(5) do
        column :user do |participation|
          participation.user&.full_name || "Unknown"
        end
        column :event do |participation|
          participation.event&.title || "Unknown Event"
        end
        column :seats
        column :status do |participation|
          status_tag participation.status.humanize, class: participation.status
        end
        column :created_at do |participation|
          participation.created_at.strftime("%d/%m/%Y")
        end
      end
    end
  end
end
