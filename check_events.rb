#!/usr/bin/env ruby

require_relative 'config/environment'

puts "=== VÉRIFICATION DES ÉVÉNEMENTS ==="
puts

Event.all.each do |event|
  puts "Event ##{event.id}: #{event.title}"
  puts "  Venue: #{event.venue_name}"
  puts "  Address: #{event.venue_address}"
  puts "  Coordinates: #{event.latitude}, #{event.longitude}"
  puts "  Status: #{event.status}"
  puts "  Date: #{event.event_date}"
  puts

  # Mettre à jour les coordonnées si elles sont manquantes
  if event.latitude.blank? || event.longitude.blank?
    puts "  ⚠️  COORDONNÉES MANQUANTES - Correction..."
    
    # Coordonnées par défaut pour les lieux de test
    case event.venue_name
    when /Grand Rex/i
      event.update_columns(latitude: 48.8719, longitude: 2.3472)
      puts "  ✅ Grand Rex geocodé"
    when /Panthéon/i
      event.update_columns(latitude: 48.8462, longitude: 2.3440)
      puts "  ✅ Panthéon geocodé"
    when /MK2/i
      event.update_columns(latitude: 48.8304, longitude: 2.3775)
      puts "  ✅ MK2 geocodé"
    else
      event.update_columns(latitude: 48.8566, longitude: 2.3522)
      puts "  ✅ Coordonnées Paris par défaut"
    end
  else
    puts "  ✅ Coordonnées OK"
  end
  
  puts "  New coordinates: #{event.reload.latitude}, #{event.longitude}"
  puts "-" * 50
end

puts
puts "Total events: #{Event.count}"
puts "Events with coordinates: #{Event.where.not(latitude: nil, longitude: nil).count}"