namespace :geocoding do
  desc "Fix geocoding for all events using enhanced geocoding service"
  task fix_all: :environment do
    puts "🌍 Starting comprehensive geocoding fix for all events..."
    
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
      original_lat = event.latitude
      original_lng = event.longitude
      original_confidence = event.geocoding_confidence
      
      # Use the OpenCage geocoding service
      geocoding_service = OpencageGeocodingService.new(
        address: event.venue_address,
        country: event.country,
        venue_name: event.venue_name
      )
      
      result = geocoding_service.geocode_with_quality_control
      
      if result[:success]
        # Update event with new geocoding data
        event.update_columns(
          latitude: result[:latitude],
          longitude: result[:longitude],
          geocoding_confidence: result[:confidence],
          coordinates_verified: result[:verified] || false,
          geocoding_status: "success"
        )
        
        puts "✅ Success: #{result[:formatted_address]} -> #{result[:latitude]}, #{result[:longitude]} (confidence: #{result[:confidence]}%)"
        
        if result[:warnings]&.any?
          puts "⚠️  Warnings: #{result[:warnings].join(', ')}"
        end
        
        # Check if this was an improvement
        if original_confidence.nil? || result[:confidence] > original_confidence
          improved_count += 1
          puts "📈 Improved confidence from #{original_confidence || 'N/A'}% to #{result[:confidence]}%"
        end
        
        success_count += 1
      else
        puts "❌ Failed: #{result[:error]}"
        
        # Update status to reflect failure
        event.update_column(:geocoding_status, "failed")
        
        if result[:suggestions]&.any?
          puts "💡 Suggestions: #{result[:suggestions].join(', ')}"
        end
        
        failed_count += 1
      end
      
      # Add a small delay to be respectful to the geocoding service
      sleep(0.5) if index < events_to_fix.count - 1
    end
    
    puts "\n🎉 Geocoding fix completed!"
    puts "📊 Results:"
    puts "   ✅ Successfully processed: #{success_count} events"
    puts "   ❌ Failed to process: #{failed_count} events"
    puts "   📈 Improved results: #{improved_count} events"
    puts "   📍 Total events processed: #{events_to_fix.count} events"
    
    # Show summary of current geocoding status
    puts "\n📈 Current geocoding status summary:"
    Event.group(:geocoding_status).count.each do |status, count|
      puts "   #{status}: #{count} events"
    end
    
    puts "\n🔍 Events still needing attention:"
    problematic_events = Event.where(
      geocoding_status: ['failed', 'error', 'service_unavailable', 'unexpected_error']
    ).limit(10)
    
    if problematic_events.any?
      problematic_events.each do |event|
        confidence_text = event.geocoding_confidence ? " (#{event.geocoding_confidence}%)" : ""
        puts "   • #{event.title} - #{event.venue_address} - Status: #{event.geocoding_status}#{confidence_text}"
      end
      
      if problematic_events.count == 10
        remaining = Event.where(geocoding_status: ['failed', 'error', 'service_unavailable', 'unexpected_error']).count - 10
        puts "   • ... and #{remaining} more events" if remaining > 0
      end
    else
      puts "   🎉 All events have been successfully geocoded!"
    end
  end
  
  desc "Show geocoding quality report"
  task quality_report: :environment do
    puts "📊 Geocoding Quality Report"
    puts "=" * 50
    
    total_events = Event.count
    puts "Total events: #{total_events}"
    
    # Status breakdown
    puts "\n🔍 Status Breakdown:"
    Event.group(:geocoding_status).count.each do |status, count|
      percentage = total_events > 0 ? (count.to_f / total_events * 100).round(1) : 0
      puts "   #{status}: #{count} events (#{percentage}%)"
    end
    
    # Confidence breakdown
    puts "\n📈 Confidence Level Breakdown:"
    high_confidence = Event.where("geocoding_confidence >= ?", 80).count
    medium_confidence = Event.where("geocoding_confidence >= ? AND geocoding_confidence < ?", 60, 80).count
    low_confidence = Event.where("geocoding_confidence < ?", 60).count
    no_confidence = Event.where(geocoding_confidence: nil).count
    
    puts "   High confidence (≥80%): #{high_confidence} events"
    puts "   Medium confidence (60-79%): #{medium_confidence} events"
    puts "   Low confidence (<60%): #{low_confidence} events"
    puts "   No confidence data: #{no_confidence} events"
    
    # Verification status
    puts "\n✓ Verification Status:"
    verified = Event.where(coordinates_verified: true).count
    unverified = Event.where(coordinates_verified: false).count
    
    puts "   Verified coordinates: #{verified} events"
    puts "   Unverified coordinates: #{unverified} events"
    
    # Problem addresses (examples)
    puts "\n⚠️  Addresses that may need attention:"
    problematic = Event.where(
      "geocoding_confidence < ? OR geocoding_status IN (?) OR coordinates_verified = false",
      70, ['failed', 'error', 'service_unavailable']
    ).limit(5)
    
    problematic.each do |event|
      puts "   • #{event.title}: #{event.venue_address} (Status: #{event.geocoding_status}, Confidence: #{event.geocoding_confidence || 'N/A'}%)"
    end
  end
end