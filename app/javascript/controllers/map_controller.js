import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    latitude: Number,
    longitude: Number,
    venueName: String,
    venueAddress: String
  }

  connect() {
    console.log("🗺️ Map controller connected")
    console.log("📍 Latitude:", this.latitudeValue)
    console.log("📍 Longitude:", this.longitudeValue)
    console.log("📏 Element dimensions:", this.element.offsetWidth, "x", this.element.offsetHeight)
    console.log("🏢 Venue:", this.venueNameValue)
    console.log("📮 Address:", this.venueAddressValue)
    
    // Hide placeholder immediately
    const placeholder = this.element.querySelector('.map-placeholder')
    if (placeholder) {
      placeholder.style.display = 'none'
    }
    
    // Wait for element to be fully rendered and Leaflet to be available
    setTimeout(() => this.initializeMap(), 300)
  }

  initializeMap() {
    // Check if Leaflet is loaded
    if (typeof L === 'undefined') {
      console.log("⏳ Leaflet not ready, retrying...")
      
      // Stop retrying after 10 seconds
      if (!this.retryCount) this.retryCount = 0
      this.retryCount++
      
      if (this.retryCount > 50) {
        console.error("❌ Leaflet failed to load after 5 seconds")
        this.showFallback("Leaflet non chargé")
        return
      }
      
      setTimeout(() => this.initializeMap(), 100)
      return
    }

    // Check if element has dimensions
    if (this.element.offsetWidth === 0 || this.element.offsetHeight === 0) {
      console.log("Element not ready, retrying...", this.element.offsetWidth, "x", this.element.offsetHeight)
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
        doubleClickZoom: true,
        zoomControl: true,
        attributionControl: true
      })

      // Add tile layer
      const tileLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 19
      })
      
      tileLayer.addTo(this.map)

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
            font-size: 12px;
          ">
            📍
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
            ${this.venueNameValue || 'Lieu de l\'événement'}
          </h3>
          <p style="color: #6b7280; margin: 0; font-size: 14px;">
            ${this.venueAddressValue || 'Adresse non disponible'}
          </p>
        </div>
      `)

      // Force refresh after initialization
      setTimeout(() => {
        this.map.invalidateSize()
        console.log("Map size invalidated and refreshed")
      }, 300)

      console.log("Map created successfully!")

    } catch (error) {
      console.error("❌ Error creating map:", error)
      this.showFallback(`Erreur: ${error.message}`)
    }
  }

  showFallback(reason) {
    console.log("🎭 Showing fallback for:", reason)
    this.element.innerHTML = `
      <div style="height: 100%; display: flex; align-items: center; justify-content: center; color: #9ca3af; flex-direction: column; padding: 20px; text-align: center;">
        <div style="font-size: 32px; margin-bottom: 12px;">📍</div>
        <p style="margin: 0 0 8px 0; font-weight: bold; color: #f59e0b;">${this.venueNameValue || 'Lieu de l\'événement'}</p>
        <p style="margin: 0; font-size: 12px; line-height: 1.4;">${this.venueAddressValue || 'Adresse non disponible'}</p>
        <p style="margin: 8px 0 0 0; font-size: 10px; opacity: 0.7;">${reason}</p>
      </div>
    `
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
    }
  }
}