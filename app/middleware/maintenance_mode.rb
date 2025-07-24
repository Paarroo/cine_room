class MaintenanceMode
  def initialize(app)
    @app = app
    @maintenance_file = Rails.root.join('tmp', 'maintenance.txt')
  end

  def call(env)
    # Skip maintenance check for admin routes and assets
    request = Rack::Request.new(env)

    if maintenance_active? && !bypass_maintenance?(request)
      maintenance_response
    else
      @app.call(env)
    end
  end

  private

  # Check if maintenance mode is active
  def maintenance_active?
    File.exist?(@maintenance_file)
  end

  # Determine if request should bypass maintenance mode
  def bypass_maintenance?(request)
    path = request.path_info

    # Allow admin routes during maintenance
    return true if path.start_with?('/admin')

    # Allow asset requests
    return true if path.start_with?('/assets', '/packs')

    # Allow health check endpoints
    return true if path.start_with?('/health', '/up')

    false
  end

  # Generate maintenance mode response
  def maintenance_response
    maintenance_info = load_maintenance_info

    html_content = generate_maintenance_html(maintenance_info)

    [
      503,
      {
        'Content-Type' => 'text/html',
        'Retry-After' => '3600' # Suggest retry after 1 hour
      },
      [ html_content ]
    ]
  end

  # Load maintenance information from file
  def load_maintenance_info
    return {} unless File.exist?(@maintenance_file)

    begin
      JSON.parse(File.read(@maintenance_file))
    rescue JSON::ParserError
      {}
    end
  end

  # Generate maintenance mode HTML page
  def generate_maintenance_html(info)
    enabled_at = info['enabled_at'] ? Time.parse(info['enabled_at']).strftime('%d/%m/%Y à %H:%M') : 'Inconnu'

    <<~HTML
      <!DOCTYPE html>
      <html lang="fr">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>CinéRoom - Maintenance en cours</title>
        <style>
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }

          body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
          }

          .maintenance-container {
            text-align: center;
            max-width: 600px;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 60px 40px;
            border: 1px solid rgba(255, 255, 255, 0.2);
          }

          .maintenance-icon {
            font-size: 80px;
            margin-bottom: 30px;
            color: #ffd700;
          }

          h1 {
            font-size: 2.5rem;
            margin-bottom: 20px;
            background: linear-gradient(45deg, #ffd700, #ffed4a);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
          }

          .maintenance-message {
            font-size: 1.2rem;
            margin-bottom: 30px;
            color: rgba(255, 255, 255, 0.8);
            line-height: 1.6;
          }

          .maintenance-details {
            background: rgba(0, 0, 0, 0.3);
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
            text-align: left;
          }

          .detail-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            font-size: 0.9rem;
          }

          .detail-label {
            color: rgba(255, 255, 255, 0.6);
          }

          .detail-value {
            color: #ffd700;
            font-weight: 500;
          }

          .back-soon {
            font-size: 1rem;
            color: rgba(255, 255, 255, 0.7);
            margin-top: 30px;
          }

          .spinner {
            border: 3px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top: 3px solid #ffd700;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
          }

          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }

          @media (max-width: 768px) {
            .maintenance-container {
              padding: 40px 20px;
            }

            h1 {
              font-size: 2rem;
            }

            .maintenance-message {
              font-size: 1rem;
            }
          }
        </style>
      </head>
      <body>
        <div class="maintenance-container">
          <div class="maintenance-icon">🔧</div>

          <h1>Maintenance en cours</h1>

          <div class="maintenance-message">
            Notre équipe travaille actuellement sur des améliorations pour vous offrir une meilleure expérience.
            Nous serons de retour très bientôt !
          </div>

          <div class="maintenance-details">
            <div class="detail-item">
              <span class="detail-label">Début de la maintenance:</span>
              <span class="detail-value">#{enabled_at}</span>
            </div>
            <div class="detail-item">
              <span class="detail-label">Statut:</span>
              <span class="detail-value">En cours</span>
            </div>
            <div class="detail-item">
              <span class="detail-label">Durée estimée:</span>
              <span class="detail-value">1-2 heures</span>
            </div>
          </div>

          <div class="spinner"></div>

          <div class="back-soon">
            Merci de votre patience. Actualisez cette page dans quelques minutes.
          </div>
        </div>

        <script>
          // Auto-refresh every 5 minutes
          setTimeout(function() {
            window.location.reload();
          }, 300000);
        </script>
      </body>
      </html>
    HTML
  end
end
