namespace :geocoding do
  desc "Fix all events using OpenCage directly (simple version)"
  task fix_events_simple: :environment do
    puts "🌍 Starting OpenCage geocoding fix for all events..."
    
    # Find events that need geocoding fixes
    events_to_fix = Event.where(
      "(latitude IS NULL OR longitude IS NULL OR geocoding_confidence IS NULL OR coordinates_verified = false OR geocoding_status IN (?, ?, ?, ?))",
      'failed', 'error', 'service_unavailable', 'unexpected_error'
    )
    
    puts "📊 Found #{events_to_fix.count} events that need geocoding fixes"
    
    success_count = 0
    failed_count = 0
    improved_count = 0
    
    events_to_fix.find_each.with_index do |event, index|
      puts "\n🔄 Processing event #{index + 1}/#{events_to_fix.count}: #{event.title} (ID: #{event.id})"
      puts "📍 Address: #{event.venue_address}"
      puts "🌎 Country: #{event.country || 'Not specified'}"
      
      # Store original state
      original_confidence = event.geocoding_confidence
      
      begin
        # Build search query
        query = event.country.present? ? "#{event.venue_address}, #{event.country}" : event.venue_address
        
        # Use OpenCage via Geocoder (already configured)
        results = Geocoder.search(query, limit: 3)
        
        if results.any?
          result = results.first
          
          # Extract confidence from OpenCage data
          confidence = 50 # default
          if result.data && result.data['confidence']
            confidence = (result.data['confidence'] * 10).to_i
          end
          
          # Update event
          event.update_columns(
            latitude: result.latitude,
            longitude: result.longitude,
            geocoding_confidence: confidence,
            coordinates_verified: true,
            geocoding_status: "success"
          )
          
          puts "✅ SUCCESS: #{result.formatted || result.address}"
          puts "   📍 Coordinates: #{result.latitude}, #{result.longitude}"
          puts "   📊 Confidence: #{confidence}%"
          if result.data && result.data['confidence']
            puts "   🌍 OpenCage confidence: #{result.data['confidence']}/10"
          end
          
          # Check if this was an improvement
          if original_confidence.nil? || confidence > original_confidence
            improved_count += 1
            puts "   📈 Improved confidence from #{original_confidence || 'N/A'}% to #{confidence}%"
          end
          
          success_count += 1
        else
          puts "❌ No results found"
          event.update_column(:geocoding_status, "failed")
          failed_count += 1
        end
        
      rescue => e
        puts "💥 ERROR: #{e.message}"
        event.update_column(:geocoding_status, "error")
        failed_count += 1
      end
      
      # Add delay between requests to respect rate limits
      sleep(0.5) if index < events_to_fix.count - 1
    end
    
    puts "\n" + "=" * 50
    puts "🎉 Geocoding fix completed!"
    puts "📊 Results:"
    puts "   ✅ Successfully processed: #{success_count} events"
    puts "   ❌ Failed to process: #{failed_count} events"
    puts "   📈 Improved results: #{improved_count} events"
    puts "   📍 Total events processed: #{events_to_fix.count} events"
    
    # Show summary of current geocoding status
    puts "\n📈 Current geocoding status summary:"
    Event.group(:geocoding_status).count.each do |status, count|
      puts "   #{status || 'unknown'}: #{count} events"
    end
    
    puts "\n🔍 Events still needing attention:"
    problematic_events = Event.where(
      geocoding_status: ['failed', 'error', 'service_unavailable', 'unexpected_error']
    ).limit(5)
    
    if problematic_events.any?
      problematic_events.each do |event|
        confidence_text = event.geocoding_confidence ? " (#{event.geocoding_confidence}%)" : ""
        puts "   • #{event.title} - #{event.venue_address} - Status: #{event.geocoding_status}#{confidence_text}"
      end
      
      remaining = Event.where(geocoding_status: ['failed', 'error', 'service_unavailable', 'unexpected_error']).count
      if remaining > 5
        puts "   • ... and #{remaining - 5} more events"
      end
    else
      puts "   🎉 All events have been successfully geocoded!"
    end
  end
end