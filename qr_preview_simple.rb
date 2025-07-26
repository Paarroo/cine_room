#!/usr/bin/env ruby

require 'json'

puts "🎬 APERÇU QR CODE CINÉROOM"
puts "=" * 50

# Données qui seront dans le QR code
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

puts "\n📊 DONNÉES ENCODÉES DANS LE QR CODE:"
puts "-" * 40
puts JSON.pretty_generate(qr_data)

puts "\n📏 CARACTÉRISTIQUES:"
puts "-" * 40
puts "• Taille des données: #{qr_json.length} caractères"
puts "• Format: JSON"
puts "• Compression: Aucune (données brutes)"

puts "\n🎫 APERÇU VISUEL QR CODE (simulation ASCII):"
puts "-" * 50

# Simulation visuelle ASCII d'un QR code
qr_visual = <<~QR
██████████████    ██  ██████████████
██          ██  ██    ██          ██
██  ██████  ██    ██  ██  ██████  ██
██  ██████  ██  ████  ██  ██████  ██
██  ██████  ██  ██    ██  ██████  ██
██          ██    ██  ██          ██
██████████████  ██  ████████████████
                ██                  
██    ██  ████    ██    ██    ██  ██
  ██████    ██  ██████    ██    ████
██    ████  ██    ████  ████  ██    
████  ██    ████    ██    ██  ████  
  ██  ████  ██    ██████    ██  ████
                ██                  
██████████████    ██████    ██  ████
██          ██  ██  ██    ████  ██  
██  ██████  ██    ████  ██████    ██
██  ██████  ██  ██    ██  ████  ██  
██  ██████  ██  ████    ██████  ████
██          ██    ██  ██    ██  ██  
██████████████  ████  ██████    ████
QR

puts qr_visual
puts "-" * 50

puts "\n🔍 INFORMATIONS TECHNIQUES:"
puts "-" * 40
puts "• Niveau de correction: Moyen (~15% d'erreur acceptable)"
puts "• Version QR: ~6 (estimation basée sur la taille des données)"
puts "• Modules: ~41x41 (estimation)"
puts "• Couleurs: Noir sur blanc"
puts "• Format de sortie: PNG 300x300px / SVG vectoriel"

puts "\n🔒 SÉCURITÉ:"
puts "-" * 40
puts "✅ Token unique de 32 caractères"
puts "✅ Participation ID pour validation croisée"
puts "✅ Horodatage de création"
puts "✅ Données utilisateur pour vérification"
puts "✅ Détails événement pour contrôle"

puts "\n📱 UTILISATION:"
puts "-" * 40
puts "1. Scanner avec n'importe quelle app QR"
puts "2. Données JSON récupérées"
puts "3. Validation du token côté serveur"
puts "4. Check-in si valide et non utilisé"

puts "\n🎯 POINTS DE VALIDATION:"
puts "-" * 40
puts "• Token correspond à la participation"
puts "• Participation confirmée (status: confirmed)"
puts "• Événement a lieu aujourd'hui"
puts "• Billet pas encore utilisé"
puts "• Utilisateur autorisé"

puts "\n🖼️ RENDU FINAL:"
puts "-" * 40
puts "Le QR code sera affiché sur:"
puts "• 📧 Email avec fond blanc, centré"
puts "• 📱 Page mobile avec design CinéRoom"
puts "• 🎫 Billet imprimable haute qualité"
puts "• 💾 Téléchargeable en PNG/SVG"

puts "\n✨ Le QR code contiendra toutes ces informations"
puts "   de manière sécurisée et scannable !"
puts "=" * 50