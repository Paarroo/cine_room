class CheckInsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_participation

  def create
    qr_token = params[:qr_token]
    
    # Verify QR token matches participation
    unless qr_token == @participation.qr_code_token
      render json: { 
        success: false, 
        message: "QR code invalide ou corrompu" 
      }, status: :unprocessable_entity and return
    end

    # Check if event is today or ongoing
    unless @participation.event.event_date.to_date == Date.current
      render json: { 
        success: false, 
        message: "Cet événement n'a pas lieu aujourd'hui" 
      }, status: :unprocessable_entity and return
    end

    # Check if already used
    if @participation.used?
      render json: { 
        success: false, 
        message: "Ce billet a déjà été utilisé le #{I18n.l(@participation.used_at, format: :short)}",
        used_at: @participation.used_at
      }, status: :unprocessable_entity and return
    end

    # Check if participation is confirmed
    unless @participation.confirmed?
      render json: { 
        success: false, 
        message: "Cette participation n'est pas confirmée" 
      }, status: :unprocessable_entity and return
    end

    # Mark as used (check-in)
    @participation.mark_as_used!
    
    Rails.logger.info "Check-in successful for participation #{@participation.id} by admin #{current_user.email}"

    render json: {
      success: true,
      message: "Entrée validée avec succès",
      participation: {
        id: @participation.id,
        user_name: @participation.user.full_name,
        user_email: @participation.user.email,
        event_title: @participation.event.title,
        seats: @participation.seats,
        checked_in_at: @participation.used_at,
        checked_in_by: current_user.full_name
      }
    }

  rescue => e
    Rails.logger.error "Check-in error for participation #{@participation.id}: #{e.message}"
    render json: { 
      success: false, 
      message: "Erreur lors de la validation de l'entrée" 
    }, status: :internal_server_error
  end

  private

  def set_participation
    @participation = Participation.find(params[:participation_id])
  end
end