# ActiveStorage configuration for production
if Rails.env.production?
  # Disable automatic analysis in production to avoid job queue issues
  Rails.application.config.after_initialize do
    ActiveStorage.silence_analyzer = true
  end
end

# Skip analysis for images in production to prevent job failures
Rails.application.config.to_prepare do
  if Rails.env.production?
    ActiveStorage::Blob.class_eval do
      def analyze_later
        # Skip analysis in production to prevent SolidQueue connection issues
        Rails.logger.info "Skipping blob analysis in production for blob #{id}"
      end
    end
  end
end