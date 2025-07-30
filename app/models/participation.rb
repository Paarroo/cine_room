class Participation < ApplicationRecord
  require 'rqrcode'
  
  belongs_to :user
  belongs_to :event

  validates :user_id, uniqueness: { scope: :event_id, message: "User already registered for this event" }
  validates :seats, numericality: { only_integer: true, greater_than: 0 }
  validates :qr_code_token, uniqueness: true, allow_blank: true
  
  enum :status, { pending: 0, confirmed: 1, cancelled: 2 }, default: :pending

  before_create :generate_qr_code_token
  after_create :generate_qr_code_data

   # Scope for upcoming events (based on event date)
  scope :upcoming, -> { joins(:event).where('events.event_date >= ?', Date.today).order('events.event_date ASC') }

  # Scope for past events
  scope :past, -> { joins(:event).where('events.event_date < ?', Date.today).order('events.event_date DESC') }

  # Dashboard metrics methods
  def self.calculate_total_revenue
    total_cents = joins(:event)
                    .where(status: :confirmed)
                    .where.not(stripe_payment_id: [nil, ''])
                    .sum('COALESCE(events.price_cents, 0) * participations.seats')
    
    total_cents / 100.0
  end

  def self.calculate_daily_revenue(date)
    total_cents = joins(:event)
                    .where(status: :confirmed)
                    .where.not(stripe_payment_id: [nil, ''])
                    .where(created_at: date.beginning_of_day..date.end_of_day)
                    .sum('COALESCE(events.price_cents, 0) * participations.seats')
    
    total_cents / 100.0
  end

  def self.revenue_chart_data
    if where(status: :confirmed).count == 0
      return generate_sample_revenue_data
    end

    (30.days.ago.to_date..Date.current).map do |date|
      revenue = calculate_daily_revenue(date)
      {
        date: date.strftime("%d/%m"),
        revenue: revenue,
        formatted_revenue: ActionController::Base.helpers.number_to_currency(revenue)
      }
    end
  end

  def self.recent_activities
    activities = []
    
    includes(:user, :event)
      .order(created_at: :desc)
      .limit(3)
      .each do |participation|
        activities << {
          type: 'participation',
          title: 'Nouvelle participation',
          description: "#{participation.user&.full_name} • #{participation.event&.title}",
          time_ago: ActionController::Base.helpers.time_ago_in_words(participation.created_at),
          icon: 'ticket-alt',
          color: 'primary'
        }
      end
    
    activities
  end

  # Check if QR code has been used for entry
  def used?
    used_at.present?
  end

  # Mark QR code as used for entry
  def mark_as_used!
    update!(used_at: Time.current)
  end

  # Generate QR code data as JSON
  def qr_code_data
    {
      participation_id: id,
      token: qr_code_token,
      user: {
        name: user&.full_name || "Utilisateur supprimé",
        email: user&.email || "Non disponible"
      },
      event: {
        title: event&.title || "Événement supprimé",
        date: event&.event_date&.strftime('%d/%m/%Y') || "Date inconnue",
        time: event&.start_time&.strftime('%H:%M') || "Heure inconnue",
        venue: event&.venue_name || "Lieu non spécifié",
        address: event&.venue_address || "Adresse non disponible"
      },
      seats: seats || 1,
      status: status || "unknown",
      created_at: created_at&.iso8601 || Time.current.iso8601
    }.to_json
  end

  # Generate QR code as PNG image data
  def qr_code_png
    return nil unless can_generate_qr_code?
    
    begin
      qr_code = RQRCode::QRCode.new(qr_code_data)
      qr_code.as_png(
        resize_gte_to: false,
        resize_exactly_to: false,
        fill: 'white',
        color: 'black',
        size: 300,
        border_modules: 4,
        module_px_size: 6
      ).to_s
    rescue => e
      Rails.logger.error "Failed to generate QR code PNG for participation #{id}: #{e.message}"
      nil
    end
  end

  # Generate QR code as SVG
  def qr_code_svg
    return nil unless can_generate_qr_code?
    
    begin
      qr_code = RQRCode::QRCode.new(qr_code_data)
      qr_code.as_svg(
        color: '000',
        shape_rendering: 'crispEdges',
        module_size: 6,
        standalone: true
      )
    rescue => e
      Rails.logger.error "Failed to generate QR code SVG for participation #{id}: #{e.message}"
      nil
    end
  end

  # Check if QR code can be safely generated
  def can_generate_qr_code?
    # Basic validation - participation must have minimum required data
    id.present? && qr_code_token.present?
  end

  private

  def self.generate_sample_revenue_data
    (30.days.ago.to_date..Date.current).map do |date|
      base_revenue = [0, 150, 250, 400, 350, 500, 300, 200].sample
      daily_variation = rand(-50..100)
      revenue = [0, base_revenue + daily_variation].max

      {
        date: date.strftime("%d/%m"),
        revenue: revenue,
        formatted_revenue: ActionController::Base.helpers.number_to_currency(revenue)
      }
    end
  end

  def generate_qr_code_token
    self.qr_code_token = SecureRandom.urlsafe_base64(32)
  end

  def generate_qr_code_data
    # Force reload to ensure qr_code_token is available
    reload
  end
end
