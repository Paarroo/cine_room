task :quick_geocode => :environment do
  puts "Geocoding events..."
  
  Event.all.each do |event|
    if event.latitude.blank? || event.longitude.blank?
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
    else
      puts "✓ #{event.title} already has coordinates"
    end
  end
  
  puts "Done!"
end