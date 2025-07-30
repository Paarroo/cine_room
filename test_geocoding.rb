#!/usr/bin/env ruby

# Test OpenCage geocoding
puts "🧪 Testing OpenCage Geocoding..."

# Test 1: Your problematic address (corrected postal code)
address1 = "Monnier et Benard Cinema, 3 Allée Richard Wallace, 91000 Évry-Courcouronnes, France"
puts "\n🔍 Test 1: #{address1}"
results1 = Geocoder.search(address1)
if results1.any?
  result = results1.first
  puts "✅ SUCCESS:"
  puts "   📍 Coordinates: #{result.latitude}, #{result.longitude}"
  puts "   🏷️  Formatted: #{result.formatted || result.address}"
  puts "   🌍 Country: #{result.country}"
  if result.data && result.data['confidence']
    puts "   📊 OpenCage confidence: #{result.data['confidence']}/10"
  end
  
  # Check if it's in France (not Africa!)
  if result.latitude.between?(41, 52) && result.longitude.between?(-5, 10)
    puts "   ✅ Coordinates are in France (not Africa!)"
  else
    puts "   ❌ Coordinates seem to be outside France"
  end
else
  puts "❌ No results found"
end

# Test 2: Simple Paris landmark
address2 = "Tour Eiffel, Paris, France"
puts "\n🔍 Test 2: #{address2}"
results2 = Geocoder.search(address2)
if results2.any?
  result = results2.first
  puts "✅ SUCCESS:"
  puts "   📍 Coordinates: #{result.latitude}, #{result.longitude}"
  puts "   🏷️  Formatted: #{result.formatted || result.address}"
  if result.data && result.data['confidence']
    puts "   📊 OpenCage confidence: #{result.data['confidence']}/10"
  end
else
  puts "❌ No results found"
end

# Test 3: The problematic original address (with wrong postal code)
address3 = "Monnier et Benard Cinema, 3 Allée Richard Wallace, 84297 Évry-Courcouronnes, France"
puts "\n🔍 Test 3: #{address3} (original with wrong postal code)"
results3 = Geocoder.search(address3)
if results3.any?
  result = results3.first
  puts "⚠️  FOUND (but probably wrong):"
  puts "   📍 Coordinates: #{result.latitude}, #{result.longitude}"
  puts "   🏷️  Formatted: #{result.formatted || result.address}"
  if result.data && result.data['confidence']
    puts "   📊 OpenCage confidence: #{result.data['confidence']}/10"
  end
  
  # Check if it's in France or somewhere else
  if result.latitude.between?(41, 52) && result.longitude.between?(-5, 10)
    puts "   ✅ Coordinates are in France"
  else
    puts "   ❌ Coordinates are OUTSIDE France (this is the bug!)"
  end
else
  puts "❌ No results found"
end

puts "\n🎉 Testing completed!"