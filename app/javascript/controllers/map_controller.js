import { Controller } from "@hotwired/stimulus"

// Connect this controller to the Stimulus application
export default class extends Controller {
  static values = { 
    latitude: Number,
    longitude: Number,
    venueName: String,
    venueAddress: String
  }
  
  static targets = ["loading"]

  connect() {
    // Wait for Leaflet to be available
    this.initializeMap();
  }

  async initializeMap() {
    // Ensure Leaflet is loaded
    if (typeof L === 'undefined') {
      // Wait a bit and try again
      setTimeout(() => this.initializeMap(), 100);
      return;
    }

    try {
      // Initialize map centered on venue coordinates or default to Paris
      const lat = parseFloat(this.latitudeValue) || 48.8566;
      const lng = parseFloat(this.longitudeValue) || 2.3522;
      
      console.log('Initializing map with coordinates:', lat, lng);
      
      // Create map instance directly on this element
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

    // Custom marker icon matching app theme
    const customIcon = L.divIcon({
      className: 'custom-marker',
      html: `
        <div class="flex items-center justify-center w-10 h-10 bg-gradient-to-br from-gold-500 to-gold-600 rounded-full text-white text-lg font-bold shadow-lg border-2 border-white">
          <i class="fas fa-map-marker-alt"></i>
        </div>
      `,
      iconSize: [40, 40],
      iconAnchor: [20, 40]
    });

    // Add marker for venue
    const marker = L.marker([lat, lng], { icon: customIcon }).addTo(this.map);
    
    // Add popup with venue information matching app theme
    const popupContent = `
      <div class="text-center p-2">
        <h3 class="font-bold text-dark-400 mb-2 text-lg">${this.venueNameValue}</h3>
        <p class="text-sm text-gray-600 mb-3">${this.venueAddressValue}</p>
        <div class="inline-flex items-center px-3 py-1 bg-gradient-to-r from-gold-500 to-gold-600 text-white text-xs font-semibold rounded-full">
          <i class="fas fa-map-marker-alt mr-1"></i>
          Lieu de l'événement
        </div>
      </div>
    `;
    
    marker.bindPopup(popupContent);

      // Fit map to show marker with some padding
      this.map.setView([lat, lng], 15);

      // Hide loading indicator
      if (this.hasLoadingTarget) {
        this.loadingTarget.style.display = 'none';
      }

    } catch (error) {
      console.error('Error initializing map:', error);
      // Show error message in loading div
      if (this.hasLoadingTarget) {
        this.loadingTarget.innerHTML = `
          <i class="fas fa-exclamation-triangle text-red-400 mr-2"></i>
          <span>Erreur de chargement de la carte</span>
        `;
      }
    }
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