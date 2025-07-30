task :quick_geocode => :environment do
  puts "Geocoding events..."
  
  Event.where("latitude IS NULL OR longitude IS NULL")
       .select(:id, :title, :venue_name, :latitude, :longitude)
       .find_each(batch_size: 100) do |event|
    puts "Geocoding: #{event.title}"
      
      # Simple geocoding fallback - set to Paris locations
      case event.venue_name
      when /Grand Rex/i
        event.update_columns(latitude: 48.8719, longitude: 2.3472)
      when /Panthéon/i
        event.update_columns(latitude: 48.8462, longitude: 2.3440)
      when /MK2/i
        event.update_columns(latitude: 48.8304, longitude: 2.3775)
      else
        # Default Paris center
        event.update_columns(latitude: 48.8566, longitude: 2.3522)
      end
      
      puts "✓ Set coordinates: #{event.latitude}, #{event.longitude}"
  end
  
  puts "Done!"
end