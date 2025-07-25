import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// Connect this controller to the Stimulus application
export default class extends Controller {
  static values = { 
    apiKey: String,
    latitude: Number,
    longitude: Number,
    venueName: String,
    venueAddress: String
  }

  connect() {
    // Initialize map centered on venue coordinates or default to Paris
    const lat = this.latitudeValue || 48.8566;
    const lng = this.longitudeValue || 2.3522;
    
    // Create map instance
    this.map = L.map(this.element, {
      center: [lat, lng],
      zoom: 15,
      scrollWheelZoom: false,
      dragging: true,
      touchZoom: true,
      doubleClickZoom: true
    });

    // Add OpenStreetMap tiles (free alternative to Google Maps)
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19
    }).addTo(this.map);

    // Custom marker icon
    const customIcon = L.divIcon({
      className: 'custom-marker',
      html: `
        <div class="flex items-center justify-center w-8 h-8 bg-gold-500 rounded-full text-white text-sm font-bold shadow-lg">
          <i class="fas fa-map-marker-alt"></i>
        </div>
      `,
      iconSize: [32, 32],
      iconAnchor: [16, 32]
    });

    // Add marker for venue
    const marker = L.marker([lat, lng], { icon: customIcon }).addTo(this.map);
    
    // Add popup with venue information
    const popupContent = `
      <div class="text-center">
        <h3 class="font-bold text-gray-800 mb-1">${this.venueNameValue}</h3>
        <p class="text-sm text-gray-600">${this.venueAddressValue}</p>
      </div>
    `;
    
    marker.bindPopup(popupContent);

    // Fit map to show marker with some padding
    this.map.setView([lat, lng], 15);
  }

  disconnect() {
    // Clean up map instance when controller is disconnected
    if (this.map) {
      this.map.remove();
    }
  }

  // Method to recenter map (can be called from other controllers)
  recenter() {
    if (this.map) {
      const lat = this.latitudeValue || 48.8566;
      const lng = this.longitudeValue || 2.3522;
      this.map.setView([lat, lng], 15);
    }
  }
}