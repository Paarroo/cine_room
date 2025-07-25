import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    latitude: Number,
    longitude: Number,
    venueName: String,
    venueAddress: String
  }

  connect() {
    console.log("Map controller connected")
    console.log("Latitude:", this.latitudeValue)
    console.log("Longitude:", this.longitudeValue)
    
    // Wait for Leaflet to be available
    this.initializeMap()
  }

  initializeMap() {
    // Check if Leaflet is loaded
    if (typeof L === 'undefined') {
      console.log("Leaflet not ready, retrying...")
      setTimeout(() => this.initializeMap(), 100)
      return
    }

    console.log("Leaflet is ready, creating map...")

    // Use provided coordinates or default to Paris
    const lat = this.latitudeValue || 48.8566
    const lng = this.longitudeValue || 2.3522

    console.log(`Creating map at: ${lat}, ${lng}`)

    try {
      // Create the map
      this.map = L.map(this.element, {
        center: [lat, lng],
        zoom: 15,
        scrollWheelZoom: false,
        dragging: true,
        touchZoom: true,
        doubleClickZoom: true
      })

      // Add tile layer
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 19
      }).addTo(this.map)

      // Create custom marker
      const customIcon = L.divIcon({
        className: 'custom-marker',
        html: `
          <div style="
            width: 30px; 
            height: 30px; 
            background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            box-shadow: 0 4px 8px rgba(0,0,0,0.3);
            border: 2px solid white;
          ">
            <i class="fas fa-map-marker-alt"></i>
          </div>
        `,
        iconSize: [30, 30],
        iconAnchor: [15, 30]
      })

      // Add marker
      const marker = L.marker([lat, lng], { icon: customIcon }).addTo(this.map)

      // Add popup
      marker.bindPopup(`
        <div style="text-align: center; padding: 8px;">
          <h3 style="color: #1f2937; margin: 0 0 8px 0; font-weight: bold;">
            ${this.venueNameValue}
          </h3>
          <p style="color: #6b7280; margin: 0; font-size: 14px;">
            ${this.venueAddressValue}
          </p>
        </div>
      `)

      console.log("Map created successfully!")

    } catch (error) {
      console.error("Error creating map:", error)
    }
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
    }
  }
}