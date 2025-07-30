class OpenCageGeocodingService
  include ActiveModel::Model
  
  attr_accessor :address, :country, :venue_name
  
  def initialize(address:, country: nil, venue_name: nil)
    @address = address
    @country = country
    @venue_name = venue_name
    @attempts = []
  end

  def geocode_with_quality_control
    Rails.logger.info "🌍 Starting OpenCage geocoding for: '#{address}' in #{country}"
    
    # Basic validation
    return create_failed_result("Address is required") if address.blank?
    return create_failed_result("Address too short (minimum 5 characters)") if address.length < 5
    
    # Try multiple geocoding strategies with OpenCage
    result = try_multiple_strategies
    
    # Verify result quality if successful
    if result[:success]
      verification = verify_coordinates(result[:latitude], result[:longitude])
      result.merge!(verification)
    end
    
    log_result(result)
    result
  end

  private

  def try_multiple_strategies
    strategies = build_strategies
    
    strategies.each_with_index do |strategy, index|
      Rails.logger.info "🔍 Trying OpenCage strategy #{index + 1}: '#{strategy[:query]}'"
      
      result = attempt_geocoding(strategy[:query], strategy[:name])
      @attempts << result
      
      if result[:success] && result[:confidence] >= strategy[:min_confidence]
        Rails.logger.info "✅ Strategy #{index + 1} succeeded with confidence #{result[:confidence]}"
        return result.merge(strategy_used: strategy[:name])
      end
      
      Rails.logger.warn "❌ Strategy #{index + 1} failed or low confidence: #{result[:error] || 'Low confidence'}"
    end
    
    # Return best attempt if all strategies failed
    best_attempt = @attempts.max_by { |a| a[:confidence] || 0 }
    best_attempt || create_failed_result("All geocoding strategies failed")
  end

  def build_strategies
    strategies = []
    
    # Strategy 1: Full address with country (if available)
    if country.present?
      strategies << {
        name: "full_address_with_country",
        query: "#{address}, #{country}",
        min_confidence: 7
      }
    end
    
    # Strategy 2: Venue name + address + country (if venue name available)
    if venue_name.present? && country.present?
      strategies << {
        name: "venue_with_address_country",
        query: "#{venue_name}, #{address}, #{country}",
        min_confidence: 8
      }
    end
    
    # Strategy 3: Just the address
    strategies << {
      name: "address_only",
      query: address,
      min_confidence: 6
    }
    
    # Strategy 4: Address with venue name (no country)
    if venue_name.present?
      strategies << {
        name: "venue_with_address",
        query: "#{venue_name}, #{address}",
        min_confidence: 6
      }
    end
    
    strategies
  end

  def attempt_geocoding(query, strategy_name)
    start_time = Time.current
    
    begin
      # Use Rails Geocoder which is now configured for OpenCage
      results = Geocoder.search(query, limit: 3)
      
      if results.empty?
        return create_failed_result("No results found for query: #{query}")
      end
      
      # Pick the best result based on OpenCage confidence
      best_result = select_best_result(results)
      
      {
        success: true,
        latitude: best_result.latitude,
        longitude: best_result.longitude,
        formatted_address: best_result.formatted_address || best_result.address,
        confidence: extract_confidence(best_result),
        response_time: (Time.current - start_time) * 1000,
        strategy: strategy_name,
        query: query,
        opencage_data: extract_opencage_details(best_result)
      }
      
    rescue Geocoder::Error => e
      create_failed_result("OpenCage geocoder error: #{e.message}")
    rescue => e
      create_failed_result("Unexpected error: #{e.message}")
    end
  end

  def select_best_result(results)
    # OpenCage provides confidence in the data, use it to select best result
    scored_results = results.map do |result|
      score = extract_confidence(result)
      
      # Boost score if country matches
      if country.present? && result.country.present?
        if country_matches?(result.country)
          score += 20
        else
          score -= 30
        end
      end
      
      { result: result, score: score }
    end
    
    scored_results.max_by { |sr| sr[:score] }[:result]
  end

  def extract_confidence(result)
    # OpenCage provides confidence in the data hash
    confidence = 50 # Default
    
    if result.data && result.data['confidence']
      # OpenCage confidence is 1-10, convert to percentage
      confidence = (result.data['confidence'] * 10).to_i
    end
    
    # Boost based on result type
    if result.data && result.data['components']
      components = result.data['components']
      confidence += 10 if components['house_number']
      confidence += 5 if components['road']
      confidence += 5 if components['city'] || components['town'] || components['village']
    end
    
    [confidence, 100].min
  end

  def extract_opencage_details(result)
    return {} unless result.data
    
    {
      confidence: result.data['confidence'],
      components: result.data['components'],
      bounds: result.data['bounds'],
      mgrs: result.data['annotations']&.dig('MGRS'),
      timezone: result.data['annotations']&.dig('timezone', 'name'),
      currency: result.data['annotations']&.dig('currency', 'name')
    }
  end

  def country_matches?(result_country)
    return false unless country.present? && result_country.present?
    
    # Simple matching - could be enhanced
    country.downcase.include?(result_country.downcase) || 
    result_country.downcase.include?(country.downcase)
  end

  def verify_coordinates(latitude, longitude)
    verification = {
      verified: true,
      warnings: [],
      country_match: true
    }
    
    # Basic coordinate validation
    if latitude.abs > 90 || longitude.abs > 180
      verification[:verified] = false
      verification[:warnings] << "Invalid coordinates detected"
      return verification
    end
    
    # Country boundary check (simplified)
    if country.present? && COUNTRY_BOUNDS.key?(country)
      bounds = COUNTRY_BOUNDS[country]
      
      lat_in_bounds = latitude.between?(bounds[:lat][0], bounds[:lat][1])
      lng_in_bounds = longitude.between?(bounds[:lng][0], bounds[:lng][1])
      
      unless lat_in_bounds && lng_in_bounds
        verification[:country_match] = false
        verification[:warnings] << "Coordinates may be outside expected country bounds"
        # Don't mark as unverified for country mismatch - OpenCage is usually right
      end
    end
    
    verification
  end

  def create_failed_result(error_message)
    {
      success: false,
      error: error_message,
      confidence: 0,
      latitude: nil,
      longitude: nil,
      attempts: @attempts.length + 1,
      suggestions: generate_suggestions(error_message)
    }
  end

  def generate_suggestions(error_message)
    suggestions = []
    
    case error_message
    when /too short/
      suggestions << "Include street number, street name, city, and country"
    when /No results found/
      suggestions << "Try a more specific address with city and postal code"
      suggestions << "Check spelling of street names and city"
    when /geocoder error/
      suggestions << "Check internet connection and API key configuration"
    end
    
    # Add French-specific suggestions
    if country == 'France'
      suggestions << "Include 5-digit postal code (like 75001 for Paris)"
      suggestions << "Use format: Number Street, Postal City, France"
    end
    
    suggestions
  end

  def log_result(result)
    if result[:success]
      Rails.logger.info "✅ OpenCage geocoding succeeded: #{address} -> #{result[:latitude]}, #{result[:longitude]} (confidence: #{result[:confidence]})"
      if result[:opencage_data] && result[:opencage_data][:confidence]
        Rails.logger.info "📊 OpenCage confidence: #{result[:opencage_data][:confidence]}/10"
      end
    else
      Rails.logger.error "❌ OpenCage geocoding failed: #{address} - #{result[:error]}"
      if result[:suggestions]&.any?
        Rails.logger.info "💡 Suggestions: #{result[:suggestions].join(', ')}"
      end
    end
  end

  # Country boundaries for basic validation
  COUNTRY_BOUNDS = {
    'France' => { lat: [41.0, 51.2], lng: [-5.5, 9.8] },
    'United States' => { lat: [18.9, 71.4], lng: [-180.0, -66.9] },
    'Canada' => { lat: [41.7, 83.1], lng: [-141.0, -52.6] },
    'United Kingdom' => { lat: [49.8, 60.9], lng: [-8.2, 1.8] },
    'Germany' => { lat: [47.3, 55.1], lng: [5.9, 15.0] },
    'Spain' => { lat: [27.6, 43.8], lng: [-18.2, 4.3] },
    'Italy' => { lat: [35.5, 47.1], lng: [6.6, 18.5] },
    'Belgium' => { lat: [49.5, 51.5], lng: [2.5, 6.4] },
    'Switzerland' => { lat: [45.8, 47.8], lng: [5.9, 10.5] },
    'Japan' => { lat: [24.0, 46.0], lng: [123.0, 146.0] },
    'Australia' => { lat: [-44.0, -10.0], lng: [113.0, 154.0] },
    'Brazil' => { lat: [-34.0, 5.3], lng: [-74.0, -32.4] }
  }.freeze
end