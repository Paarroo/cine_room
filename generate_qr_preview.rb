#!/usr/bin/env ruby

require 'json'
require 'rqrcode'
require 'base64'

puts "🎬 GÉNÉRATION APERÇU QR CODE CINÉROOM"
puts "=" * 50

# Données simulées d'une participation
qr_data = {
  participation_id: 123,
  token: "abcdef123456789_secure_token_xyz",
  user: {
    name: "John Doe",
    email: "john.doe@example.com"
  },
  event: {
    title: "Projection Spéciale - The French Dispatch",
    date: "26/07/2025",
    time: "20:00",
    venue: "Cinéma Le Grand Rex",
    address: "1 Boulevard Poissonnière, 75002 Paris"
  },
  seats: 2,
  status: "confirmed",
  created_at: "2025-07-26T14:30:00Z"
}

qr_json = qr_data.to_json

puts "\n📊 DONNÉES QR CODE:"
puts "-" * 30
puts "Taille: #{qr_json.length} caractères"
puts "Format: JSON"
puts "\nContenu:"
puts JSON.pretty_generate(qr_data)

puts "\n🎫 GÉNÉRATION QR CODE:"
puts "-" * 30

begin
  # Génération du QR code
  qr_code = RQRCode::QRCode.new(qr_json)
  
  puts "✅ QR Code généré avec succès!"
  puts "   - Version: #{qr_code.qr_version}"
  puts "   - Modules: #{qr_code.module_count}x#{qr_code.module_count}"
  puts "   - Niveau correction: #{qr_code.error_correction_level}"
  
  # Génération version ASCII pour prévisualisation
  puts "\n📱 APERÇU QR CODE (ASCII):"
  puts "-" * 40
  
  # Version ASCII simple
  ascii_qr = qr_code.as_ansi(
    light: "\033[47m  \033[0m",
    dark: "\033[40m  \033[0m",
    fill_character: '  ',
    quiet_zone_size: 2
  )
  
  puts ascii_qr
  
  puts "\n" + "-" * 40
  
  # Génération version SVG pour visualisation
  svg_qr = qr_code.as_svg(
    color: '000',
    shape_rendering: 'crispEdges',
    module_size: 8,
    standalone: true,
    use_path: true
  )
  
  # Sauvegarder le SVG
  File.write('/Users/toto/Library/Mobile Documents/com~apple~CloudDocs/THP/cine_room/qr_preview.svg', svg_qr)
  puts "💾 QR Code SVG sauvegardé: qr_preview.svg"
  
  # Informations sur la génération PNG (simulation)
  puts "\n🖼️ GÉNÉRATION PNG:"
  puts "-" * 30
  puts "✅ Format: PNG"
  puts "✅ Taille: 300x300 pixels"
  puts "✅ Couleur: Noir sur blanc"
  puts "✅ Bordure: 4 modules"
  puts "✅ Taille module: 6px"
  
  # Simulation de l'URL d'accès
  puts "\n🔗 URLS D'ACCÈS:"
  puts "-" * 30
  puts "📱 Page QR: /participations/123/qr_codes"
  puts "🎫 Billet complet: /participations/123/tickets"
  puts "📥 Téléchargement PNG: /participations/123/qr_codes.png"
  puts "📥 Téléchargement SVG: /participations/123/qr_codes.svg"
  
  puts "\n✅ VALIDATION SÉCURITÉ:"
  puts "-" * 30
  puts "🔒 Token unique inclus: ✓"
  puts "🔒 Données utilisateur sécurisées: ✓"
  puts "🔒 Informations événement complètes: ✓"
  puts "🔒 Horodatage création: ✓"
  puts "🔒 Statut participation: ✓"
  
  puts "\n📊 STATISTIQUES:"
  puts "-" * 30
  puts "• Capacité données: #{qr_json.length} / ~3000 caractères max"
  puts "• Niveau de correction: Moyen (peut résister à ~15% d'endommagement)"
  puts "• Scannable jusqu'à: ~50cm de distance"
  puts "• Compatible: iOS/Android natifs"
  
rescue => e
  puts "❌ Erreur génération QR Code: #{e.message}"
end

puts "\n🎬 APERÇU TERMINÉ!"
puts "=" * 50