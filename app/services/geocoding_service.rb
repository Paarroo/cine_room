class OpenCageGeocodingService
  include ActiveModel::Model
  
  attr_accessor :address, :country, :venue_name
  
  # Country boundaries for validation (simplified - OpenCage handles most of this)
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
  
  def initialize(address:, country: nil, venue_name: nil)
    @address = address
    @country = country
    @venue_name = venue_name
    @attempts = []
    @final_result = nil
  end
  
  def geocode_with_quality_control
    Rails.logger.info "🌍 Starting enhanced geocoding for: '#{address}' in #{country}"
    
    # Step 1: Validate address format
    validation_result = validate_address_format
    unless validation_result[:valid]
      return create_failed_result("Address validation failed: #{validation_result[:errors].join(', ')}")
    end
    
    # Step 2: Try multiple geocoding strategies
    result = try_multiple_geocoding_strategies
    
    # Step 3: Verify result quality
    if result[:success]
      verification = verify_geocoding_result(result[:latitude], result[:longitude])
      result.merge!(verification)
    end
    
    # Step 4: Log final result
    log_geocoding_result(result)
    
    result
  end
  
  private
  
  def validate_address_format
    errors = []
    
    # Basic length check
    if address.length < 10
      errors << "Address too short (should be at least 10 characters)"
    end
    
    # Country-specific validation
    if country.present?
      country_errors = validate_country_specific_format
      errors.concat(country_errors)
    end
    
    # Check for minimum required components
    unless address.match?(/\d/) # Should have at least one number
      errors << "Address should include a street number"
    end
    
    unless address.include?(',') || address.match?(/\s+\w+\s+\w+/) # Either comma or multiple words
      errors << "Address should include street and city information"
    end
    
    {
      valid: errors.empty?,
      errors: errors,
      suggestions: generate_address_suggestions(errors)
    }
  end
  
  def validate_country_specific_format
    return [] unless country.present?
    
    errors = []
    
    case country
    when 'France'
      errors.concat(validate_french_address)
    when 'United States'
      errors.concat(validate_us_address)
    when 'Canada'
      errors.concat(validate_canadian_address)
    # Add more countries as needed
    end
    
    errors
  end
  
  def validate_french_address
    errors = []
    
    # Check for postal code
    postal_match = address.match(/\b(\d{5})\b/)
    if postal_match
      postal_code = postal_match[1]
      
      # Validate postal code format
      unless postal_code.match?(POSTAL_CODE_PATTERNS['France'])
        errors << "Invalid French postal code format: #{postal_code}"
      end
      
      # Check for common French postal code errors
      if postal_code.start_with?('84') && address.downcase.include?('évry')
        errors << "Invalid postal code 84xxx for Évry-Courcouronnes (should be 91xxx)"
      end
    else
      errors << "French address should include a 5-digit postal code"
    end
    
    errors
  end
  
  def validate_us_address
    errors = []
    
    # Check for state abbreviation or ZIP code
    unless address.match?(/\b[A-Z]{2}\b/) || address.match?(/\b\d{5}(-\d{4})?\b/)
      errors << "US address should include state or ZIP code"
    end
    
    errors
  end
  
  def validate_canadian_address
    errors = []
    
    # Check for postal code format
    unless address.match?(/\b[A-Z]\d[A-Z] ?\d[A-Z]\d\b/i)
      errors << "Canadian address should include postal code (format: A1A 1A1)"
    end
    
    errors
  end
  
  def try_multiple_geocoding_strategies
    strategies = build_geocoding_strategies
    
    strategies.each_with_index do |strategy, index|
      Rails.logger.info "🔍 Trying geocoding strategy #{index + 1}: '#{strategy[:query]}'"
      
      result = attempt_geocoding(strategy[:query], strategy[:name])
      @attempts << result
      
      if result[:success] && result[:confidence] >= strategy[:min_confidence]
        Rails.logger.info "✅ Strategy #{index + 1} succeeded with confidence #{result[:confidence]}"
        return result.merge(strategy_used: strategy[:name])
      end
      
      Rails.logger.warn "❌ Strategy #{index + 1} failed or low confidence: #{result[:error] || 'Low confidence'}"
    end
    
    # If all strategies failed, return the best attempt
    best_attempt = @attempts.max_by { |a| a[:confidence] || 0 }
    best_attempt || create_failed_result("All geocoding strategies failed")
  end
  
  def build_geocoding_strategies
    base_strategies = [
      {
        name: "full_address_with_country",
        query: country.present? ? "#{address}, #{country}" : address,
        min_confidence: 80
      },
      {
        name: "address_only",
        query: address,
        min_confidence: 70
      }
    ]
    
    # Add venue name strategy if available
    if venue_name.present?
      base_strategies.unshift({
        name: "venue_with_address",
        query: country.present? ? "#{venue_name}, #{address}, #{country}" : "#{venue_name}, #{address}",
        min_confidence: 85
      })
    end
    
    # Add city extraction strategy
    city_match = extract_city_from_address
    if city_match
      base_strategies << {
        name: "city_country_fallback",
        query: country.present? ? "#{city_match}, #{country}" : city_match,
        min_confidence: 60
      }
    end
    
    base_strategies
  end
  
  def attempt_geocoding(query, strategy_name)
    start_time = Time.current
    
    begin
      results = Geocoder.search(query, limit: 3)
      
      if results.empty?
        return create_failed_result("No results found for query: #{query}")
      end
      
      # Pick the best result
      best_result = select_best_geocoding_result(results, query)
      
      {
        success: true,
        latitude: best_result.latitude,
        longitude: best_result.longitude,
        formatted_address: best_result.formatted_address || best_result.address,
        confidence: calculate_confidence(best_result, query),
        response_time: (Time.current - start_time) * 1000,
        strategy: strategy_name,
        query: query
      }
      
    rescue Geocoder::Error => e
      create_failed_result("Geocoder error: #{e.message}")
    rescue => e
      create_failed_result("Unexpected error: #{e.message}")
    end
  end
  
  def select_best_geocoding_result(results, query)
    # Score each result based on various factors
    scored_results = results.map do |result|
      score = 0
      
      # Prefer results with higher precision
      score += 20 if result.precision == "exact"
      score += 15 if result.precision == "high"
      score += 10 if result.precision == "medium"
      
      # Prefer results in the expected country
      if country.present? && result.country.present?
        score += 30 if result.country.downcase.include?(country.downcase) || 
                       country.downcase.include?(result.country.downcase)
      end
      
      # Prefer results with address components
      score += 10 if result.formatted_address.present?
      score += 5 if result.city.present?
      
      { result: result, score: score }
    end
    
    # Return the highest scoring result
    scored_results.max_by { |sr| sr[:score] }[:result]
  end
  
  def calculate_confidence(result, query)
    confidence = 50 # Base confidence
    
    # Boost confidence based on result quality
    confidence += 20 if result.precision == "exact"
    confidence += 15 if result.precision == "high"
    confidence += 10 if result.precision == "medium"
    
    # Boost if country matches
    if country.present? && result.country.present?
      if result.country.downcase.include?(country.downcase) || 
         country.downcase.include?(result.country.downcase)
        confidence += 20
      else
        confidence -= 30 # Penalize wrong country
      end
    end
    
    # Boost if key components match
    query_words = query.downcase.split(/\W+/)
    result_words = (result.formatted_address || result.address || "").downcase.split(/\W+/)
    
    matching_words = (query_words & result_words).length
    confidence += [matching_words * 2, 20].min
    
    [confidence, 100].min
  end
  
  def verify_geocoding_result(latitude, longitude)
    verification = {
      verified: true,
      warnings: [],
      country_match: true
    }
    
    # Check if coordinates are within expected country bounds
    if country.present? && COUNTRY_BOUNDS.key?(country)
      bounds = COUNTRY_BOUNDS[country]
      
      lat_in_bounds = latitude.between?(bounds[:lat][0], bounds[:lat][1])
      lng_in_bounds = longitude.between?(bounds[:lng][0], bounds[:lng][1])
      
      unless lat_in_bounds && lng_in_bounds
        verification[:country_match] = false
        verification[:warnings] << "Coordinates (#{latitude}, #{longitude}) are outside expected bounds for #{country}"
        verification[:verified] = false
      end
    end
    
    # Check for obviously wrong coordinates (oceans, poles, etc.)
    if latitude.abs > 85 || longitude.abs > 175
      verification[:warnings] << "Coordinates appear to be in an extreme location"
      verification[:verified] = false
    end
    
    verification
  end
  
  def extract_city_from_address
    # Try to extract city name from address
    # This is a simplified version - could be enhanced with more sophisticated parsing
    parts = address.split(',').map(&:strip)
    
    if parts.length >= 2
      # Assume the last part before country is the city
      city_part = parts[-1]
      
      # Remove postal code if present
      city_part.gsub(/\b\d{4,5}\b/, '').strip
    end
  end
  
  def generate_address_suggestions(errors)
    suggestions = []
    
    if errors.include?("Address too short (should be at least 10 characters)")
      suggestions << "Try including more details like street number, street name, city, and postal code"
    end
    
    if errors.any? { |e| e.include?("postal code") }
      suggestions << "Check that the postal code matches the city"
      suggestions << "For French addresses, use 5-digit postal codes (like 75001 for Paris)"
    end
    
    suggestions
  end
  
  def create_failed_result(error_message)
    {
      success: false,
      error: error_message,
      confidence: 0,
      latitude: nil,
      longitude: nil,
      attempts: @attempts.length + 1
    }
  end
  
  def log_geocoding_result(result)
    if result[:success]
      Rails.logger.info "✅ Enhanced geocoding succeeded: #{address} -> #{result[:latitude]}, #{result[:longitude]} (confidence: #{result[:confidence]}%)"
    else
      Rails.logger.error "❌ Enhanced geocoding failed: #{address} - #{result[:error]}"
      Rails.logger.error "📊 Tried #{@attempts.length} strategies: #{@attempts.map { |a| a[:strategy] }.join(', ')}"
    end
  end
end