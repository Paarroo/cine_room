Rails.application.configure do
  # Security headers configuration
  config.force_ssl = true if Rails.env.production?
  
  # Add security headers middleware
  config.middleware.use Rack::Attack if defined?(Rack::Attack)
  
  # Configure additional security headers
  config.after_initialize do
    # X-Frame-Options
    ActionDispatch::Response.default_headers['X-Frame-Options'] = 'DENY'
    
    # X-Content-Type-Options
    ActionDispatch::Response.default_headers['X-Content-Type-Options'] = 'nosniff'
    
    # X-XSS-Protection
    ActionDispatch::Response.default_headers['X-XSS-Protection'] = '1; mode=block'
    
    # Referrer-Policy
    ActionDispatch::Response.default_headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    
    # Permissions-Policy
    ActionDispatch::Response.default_headers['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'
    
    # Strict-Transport-Security (HSTS) - only for production
    if Rails.env.production?
      ActionDispatch::Response.default_headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains; preload'
    end
  end
end