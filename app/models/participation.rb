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
        name: user.full_name,
        email: user.email
      },
      event: {
        title: event.title,
        date: event.event_date.strftime('%d/%m/%Y'),
        time: event.start_time.strftime('%H:%M'),
        venue: event.venue_name,
        address: event.venue_address
      },
      seats: seats,
      status: status,
      created_at: created_at.iso8601
    }.to_json
  end

  # Generate QR code as PNG image data
  def qr_code_png
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
  end

  # Generate QR code as SVG
  def qr_code_svg
    qr_code = RQRCode::QRCode.new(qr_code_data)
    qr_code.as_svg(
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 6,
      standalone: true
    )
  end

  private

  def generate_qr_code_token
    self.qr_code_token = SecureRandom.urlsafe_base64(32)
  end

  def generate_qr_code_data
    # Force reload to ensure qr_code_token is available
    reload
  end
end
