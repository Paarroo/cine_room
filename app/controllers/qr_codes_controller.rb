class QrCodesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_participation

  def show
    ensure_owner_or_admin!(@participation)
    
    respond_to do |format|
      format.html # Show QR code page
      format.png do
        begin
          qr_png = @participation.qr_code_png
          send_data qr_png,
                    type: 'image/png',
                    filename: "ticket_qr_#{@participation.id}.png",
                    disposition: 'inline'
        rescue => e
          Rails.logger.error "QR PNG generation error: #{e.message}"
          # Fallback avec image simple
          redirect_to asset_path('qr_placeholder.png')
        end
      end
      format.svg do
        begin
          render xml: @participation.qr_code_svg,
                 content_type: 'image/svg+xml'
        rescue => e
          Rails.logger.error "QR SVG generation error: #{e.message}"
          render xml: qr_fallback_svg, content_type: 'image/svg+xml'
        end
      end
      format.json do
        render json: {
          participation_id: @participation.id,
          qr_code_data: JSON.parse(@participation.qr_code_data),
          used: @participation.used?,
          used_at: @participation.used_at
        }
      end
    end
  end

  private

  def set_participation
    @participation = Participation.find(params[:participation_id])
  end

  def ensure_owner_or_admin!(participation)
    unless participation.user == current_user || current_user&.admin?
      flash[:alert] = "Vous ne pouvez accéder qu'à vos propres billets."
      redirect_to root_path
    end
  end

  def qr_fallback_svg
    <<~SVG
      <svg width="300" height="300" xmlns="http://www.w3.org/2000/svg">
        <rect width="300" height="300" fill="#f3f4f6"/>
        <text x="150" y="130" text-anchor="middle" font-family="Arial" font-size="16" fill="#6b7280">
          QR Code
        </text>
        <text x="150" y="150" text-anchor="middle" font-family="Arial" font-size="16" fill="#6b7280">
          Indisponible
        </text>
        <text x="150" y="180" text-anchor="middle" font-family="Arial" font-size="48" fill="#9ca3af">
          🎫
        </text>
      </svg>
    SVG
  end
end