namespace :geocoding do
  desc "Test OpenCage geocoding with problematic addresses"
  task test_opencage: :environment do
    puts "🧪 Testing OpenCage Geocoding Service"
    puts "=" * 50
    
    # Check if API key is configured
    if ENV['OPENCAGE_API_KEY'].blank? || ENV['OPENCAGE_API_KEY'] == 'your_opencage_api_key_here'
      puts "❌ ERROR: OpenCage API key not configured!"
      puts "Please:"
      puts "1. Go to https://opencagedata.com/api"
      puts "2. Sign up for a free account (2,500 requests/day)"
      puts "3. Get your API key"
      puts "4. Set OPENCAGE_API_KEY in your .env file"
      exit 1
    end
    
    # Test addresses - including the problematic ones you mentioned
    test_addresses = [
      {
        address: "Monnier et Benard Cinema, 3 Allée Richard Wallace, 91000 Évry-Courcouronnes",
        country: "France",
        venue_name: "Monnier et Benard Cinema",
        description: "Fixed postal code for Évry-Courcouronnes (was 84297, now 91000)"
      },
      {
        address: "Tour Eiffel, Paris",
        country: "France",
        venue_name: "Tour Eiffel",
        description: "Simple famous landmark"
      },
      {
        address: "Times Square, New York, NY",
        country: "United States",
        venue_name: "Times Square",
        description: "US landmark"
      },
      {
        address: "1600 Pennsylvania Avenue NW, Washington, DC 20500",
        country: "United States",
        venue_name: "White House",
        description: "Full US address with ZIP code"
      },
      {
        address: "invalid address xyz123",
        country: "France",
        venue_name: nil,
        description: "Invalid address to test error handling"
      }
    ]
    
    success_count = 0
    total_count = test_addresses.length
    
    test_addresses.each_with_index do |test_case, index|
      puts "\n🔍 Test #{index + 1}/#{total_count}: #{test_case[:description]}"
      puts "Address: #{test_case[:address]}"
      puts "Country: #{test_case[:country]}"
      puts "Venue: #{test_case[:venue_name] || 'None'}"
      
      begin
        service = OpenCageGeocodingService.new(
          address: test_case[:address],
          country: test_case[:country],
          venue_name: test_case[:venue_name]
        )
        
        result = service.geocode_with_quality_control
        
        if result[:success]
          puts "✅ SUCCESS:"
          puts "   📍 Coordinates: #{result[:latitude]}, #{result[:longitude]}"
          puts "   📊 Confidence: #{result[:confidence]}%"
          puts "   🏷️  Formatted: #{result[:formatted_address]}"
          puts "   ⚡ Response time: #{result[:response_time].round(2)}ms"
          puts "   🎯 Strategy: #{result[:strategy_used]}"
          
          if result[:opencage_data] && result[:opencage_data][:confidence]
            puts "   🌍 OpenCage confidence: #{result[:opencage_data][:confidence]}/10"
          end
          
          if result[:warnings]&.any?
            puts "   ⚠️  Warnings: #{result[:warnings].join(', ')}"
          end
          
          success_count += 1
        else
          puts "❌ FAILED: #{result[:error]}"
          if result[:suggestions]&.any?
            puts "   💡 Suggestions: #{result[:suggestions].join(', ')}"
          end
        end
        
      rescue => e
        puts "💥 EXCEPTION: #{e.message}"
        puts "   #{e.backtrace.first}"
      end
      
      # Add delay between requests to respect rate limits
      sleep(1) if index < test_addresses.length - 1
    end
    
    puts "\n" + "=" * 50
    puts "🎉 Testing completed!"
    puts "📊 Results: #{success_count}/#{total_count} addresses successfully geocoded"
    puts "📈 Success rate: #{((success_count.to_f / total_count) * 100).round(1)}%"
    
    if success_count == total_count - 1 # All except the intentionally invalid one
      puts "✅ OpenCage geocoding is working perfectly!"
      puts "You can now run: rails geocoding:fix_all"
    elsif success_count > 0
      puts "⚠️  OpenCage is working but some addresses failed"
      puts "This might be normal for invalid addresses"
    else
      puts "❌ OpenCage geocoding is not working properly"
      puts "Please check your API key and internet connection"
    end
  end
  
  desc "Quick test with a single address"
  task :test_single, [:address] => :environment do |t, args|
    address = args[:address] || "Tour Eiffel, Paris, France"
    
    puts "🧪 Quick test with: #{address}"
    
    service = OpenCageGeocodingService.new(address: address, country: "France")
    result = service.geocode_with_quality_control
    
    if result[:success]
      puts "✅ Success: #{result[:latitude]}, #{result[:longitude]} (#{result[:confidence]}%)"
    else
      puts "❌ Failed: #{result[:error]}"
    end
  end
end