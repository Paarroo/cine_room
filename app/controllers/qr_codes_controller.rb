class QrCodesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_participation

  def show
    ensure_owner_or_admin!(@participation)
    
    respond_to do |format|
      format.html # Show QR code page
      format.png do
        send_data @participation.qr_code_png,
                  type: 'image/png',
                  filename: "ticket_qr_#{@participation.id}.png",
                  disposition: 'inline'
      end
      format.svg do
        render xml: @participation.qr_code_svg,
               content_type: 'image/svg+xml'
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
end