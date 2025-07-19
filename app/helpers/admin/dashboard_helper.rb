module Admin::DashboardHelper
  # Generate revenue chart data for the last 30 days
  def revenue_chart_data
    @revenue_chart_data ||= begin
      (30.days.ago.to_date..Date.current).map do |date|
        revenue = Participation.where(status: :confirmed)
                              .where(created_at: date.beginning_of_day..date.end_of_day)
                              .joins(:event)
                              .sum("events.price_cents * participations.seats") / 100.0

        {
          date: date.strftime("%d/%m"),
          revenue: revenue,
          formatted_revenue: number_to_currency(revenue)
        }
      end
    end
  end

  # Generate events status chart data
  def events_status_chart_data
    @events_status_chart_data ||= begin
      status_counts = Event.group(:status).count
      total_events = status_counts.values.sum

      status_counts.map do |status, count|
        {
          status: status.humanize,
          count: count,
          percentage: total_events.zero? ? 0 : ((count.to_f / total_events) * 100).round(1),
          color: status_color(status)
        }
      end
    end
  end

  # Generate user growth chart data
  def user_growth_chart_data
    @user_growth_chart_data ||= begin
      (12.months.ago.beginning_of_month..Date.current.end_of_month).group_by(&:month).map do |month, dates|
        month_start = dates.first.beginning_of_month
        month_end = dates.first.end_of_month

        new_users = User.where(created_at: month_start..month_end).count

        {
          month: month_start.strftime("%b %Y"),
          users: new_users,
          cumulative: User.where(created_at: ..month_end).count
        }
      end
    end
  end

  # Generate participation trends data
  def participation_trends_data
    @participation_trends_data ||= begin
      (7.days.ago.to_date..Date.current).map do |date|
        daily_participations = Participation.where(created_at: date.beginning_of_day..date.end_of_day)

        {
          date: date.strftime("%a %d"),
          confirmed: daily_participations.where(status: :confirmed).count,
          pending: daily_participations.where(status: :pending).count,
          cancelled: daily_participations.where(status: :cancelled).count
        }
      end
    end
  end
