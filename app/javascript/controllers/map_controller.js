import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    latitude: Number,
    longitude: Number,
    venueName: String,
    venueAddress: String
  }

  connect() {
    
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
      
      // Stop retrying after 10 seconds
      if (!this.retryCount) this.retryCount = 0
      this.retryCount++
      
      if (this.retryCount > 50) {
        console.error("❌ Leaflet failed to load after 5 seconds")
        this.showFallback("Leaflet not loaded")
        return
      }
      
      setTimeout(() => this.initializeMap(), 100)
      return
    }

    // Check if element has dimensions
    if (this.element.offsetWidth === 0 || this.element.offsetHeight === 0) {
      setTimeout(() => this.initializeMap(), 100)
      return
    }


    // Use provided coordinates or default to Paris
    const lat = this.latitudeValue || 48.8566
    const lng = this.longitudeValue || 2.3522


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

      // Add custom controls
      this.addGpsControl()
      this.addResizeControl()

      // Force refresh after initialization
      setTimeout(() => {
        this.map.invalidateSize()
      }, 300)


    } catch (error) {
      console.error("❌ Error creating map:", error)
      this.showFallback(`Erreur: ${error.message}`)
    }
  }

  addGpsControl() {
    // Create custom GPS control
    const GpsControl = L.Control.extend({
      options: {
        position: 'topleft'
      },

      onAdd: (map) => {
        const container = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-gps')
        
        // GPS button
        const button = L.DomUtil.create('a', 'leaflet-control-gps-button', container)
        button.innerHTML = '<span style="font-size: 14px;">🧭</span>'
        button.href = '#'
        button.title = 'Open in GPS'
        
        // Style du bouton
        button.style.display = 'flex'
        button.style.alignItems = 'center'
        button.style.justifyContent = 'center'
        button.style.width = '30px'
        button.style.height = '30px'
        button.style.textDecoration = 'none'
        button.style.fontWeight = 'bold'
        
        // Event handler
        L.DomEvent.on(button, 'click', (e) => {
          L.DomEvent.stopPropagation(e)
          L.DomEvent.preventDefault(e)
          this.openInGps()
        })
        
        return container
      }
    })

    // Add control to map
    this.map.addControl(new GpsControl())
  }

  openInGps() {
    
    // Check if geolocation is available
    if (!navigator.geolocation) {
      this.openGpsWithoutUserLocation()
      return
    }

    // Afficher l'indicateur de chargement
    this.showGpsLoading(true)

    // Demander la position de l'utilisateur
    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.showGpsLoading(false)
        const userLat = position.coords.latitude
        const userLng = position.coords.longitude
        
        // Destination coordinates
        const destLat = this.latitudeValue || 48.8566
        const destLng = this.longitudeValue || 2.3522
        const address = this.venueAddressValue || this.venueNameValue || 'Destination'
        
        // Open GPS app with route
        this.openGpsWithRoute(userLat, userLng, destLat, destLng, address)
      },
      (error) => {
        this.showGpsLoading(false)
        this.handleGeolocationError(error)
        
        // Fallback: open without user position
        this.openGpsWithoutUserLocation()
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 300000
      }
    )
  }

  openGpsWithoutUserLocation() {
    // Destination coordinates only
    const lat = this.latitudeValue || 48.8566
    const lng = this.longitudeValue || 2.3522
    const address = this.venueAddressValue || this.venueNameValue || 'Destination'
    
    // Detect platform and open appropriate GPS app
    if (this.isIOS()) {
      this.openAppleMaps(lat, lng, address)
    } else if (this.isAndroid()) {
      this.openAndroidGps(lat, lng, address)
    } else {
      this.openDesktopGps(lat, lng, address)
    }
  }

  openGpsWithRoute(userLat, userLng, destLat, destLng, address) {
    // Detect platform and open GPS app with complete route
    if (this.isIOS()) {
      this.openAppleMapsWithRoute(userLat, userLng, destLat, destLng, address)
    } else if (this.isAndroid()) {
      this.openAndroidGpsWithRoute(userLat, userLng, destLat, destLng, address)
    } else {
      this.openDesktopGpsWithRoute(userLat, userLng, destLat, destLng)
    }
  }

  openAppleMaps(lat, lng, address) {
    const url = `maps://?daddr=${lat},${lng}&q=${encodeURIComponent(address)}`
    window.location.href = url
    
    // Fallback after 2 seconds if app doesn't open
    setTimeout(() => {
      this.openOpenStreetMapDirections(lat, lng)
    }, 2000)
  }

  openAndroidGps(lat, lng, address) {
    const url = `geo:${lat},${lng}?q=${lat},${lng}(${encodeURIComponent(address)})`
    window.location.href = url
    
    // Fallback after 2 seconds if app doesn't open
    setTimeout(() => {
      this.openOpenStreetMapDirections(lat, lng)
    }, 2000)
  }

  openDesktopGps(lat, lng, address) {
    // On desktop, open OpenStreetMap directly
    this.openOpenStreetMapDirections(lat, lng)
  }

  openAppleMapsWithRoute(userLat, userLng, destLat, destLng, address) {
    const url = `maps://?saddr=${userLat},${userLng}&daddr=${destLat},${destLng}&q=${encodeURIComponent(address)}`
    window.location.href = url
    
    // Fallback after 2 seconds if app doesn't open
    setTimeout(() => {
      this.openOpenStreetMapDirectionsWithRoute(userLat, userLng, destLat, destLng)
    }, 2000)
  }

  openAndroidGpsWithRoute(userLat, userLng, destLat, destLng, address) {
    const url = `google.navigation:q=${destLat},${destLng}&mode=d`
    window.location.href = url
    
    // Fallback after 2 seconds if app doesn't open
    setTimeout(() => {
      this.openOpenStreetMapDirectionsWithRoute(userLat, userLng, destLat, destLng)
    }, 2000)
  }

  openDesktopGpsWithRoute(userLat, userLng, destLat, destLng) {
    // On desktop, open OpenStreetMap with complete route
    this.openOpenStreetMapDirectionsWithRoute(userLat, userLng, destLat, destLng)
  }

  openOpenStreetMapDirections(lat, lng) {
    const url = `https://www.openstreetmap.org/directions?to=${lat}%2C${lng}`
    window.open(url, '_blank')
  }

  openOpenStreetMapDirectionsWithRoute(fromLat, fromLng, toLat, toLng) {
    const url = `https://www.openstreetmap.org/directions?from=${fromLat}%2C${fromLng}&to=${toLat}%2C${toLng}`
    window.open(url, '_blank')
  }

  isIOS() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent)
  }

  isAndroid() {
    return /Android/.test(navigator.userAgent)
  }

  showGpsLoading(show) {
    const gpsButton = this.element.querySelector('.leaflet-control-gps-button')
    if (gpsButton) {
      if (show) {
        gpsButton.innerHTML = '<span style="font-size: 12px;">⏳</span>'
        gpsButton.style.opacity = '0.7'
        gpsButton.title = 'Localisation en cours...'
      } else {
        gpsButton.innerHTML = '<span style="font-size: 14px;">🧭</span>'
        gpsButton.style.opacity = '1'
        gpsButton.title = 'Ouvrir dans le GPS'
      }
    }
  }

  handleGeolocationError(error) {
    let message = 'Erreur de géolocalisation'
    
    switch(error.code) {
      case error.PERMISSION_DENIED:
        message = 'Permission de géolocalisation refusée'
        break
      case error.POSITION_UNAVAILABLE:
        message = 'Position non disponible'
        break
      case error.TIMEOUT:
        message = 'Timeout de géolocalisation'
        break
      default:
        break
    }
    
  }

  addResizeControl() {
    // Create custom fullscreen control
    const FullscreenControl = L.Control.extend({
      options: {
        position: 'topleft' // Position next to zoom controls
      },

      onAdd: (map) => {
        const container = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-fullscreen')
        
        // Fullscreen button
        const button = L.DomUtil.create('a', 'leaflet-control-fullscreen-button', container)
        button.innerHTML = '<span style="font-size: 12px;">⛶</span>' // Fullscreen icon
        button.href = '#'
        button.title = 'Plein écran'
        
        // Style du bouton
        button.style.display = 'flex'
        button.style.alignItems = 'center'
        button.style.justifyContent = 'center'
        button.style.width = '30px'
        button.style.height = '30px'
        button.style.textDecoration = 'none'
        button.style.fontWeight = 'bold'
        
        // Event handler
        L.DomEvent.on(button, 'click', (e) => {
          L.DomEvent.stopPropagation(e)
          L.DomEvent.preventDefault(e)
          this.openFullscreen()
        })
        
        return container
      }
    })

    // Add control to map
    this.map.addControl(new FullscreenControl())
  }

  openFullscreen() {
    
    // Create fullscreen modal
    const modal = this.createModal()
    document.body.appendChild(modal)
    
    // Prevent body scroll
    document.body.style.overflow = 'hidden'
    
    // Create map in modal
    setTimeout(() => this.initializeFullscreenMap(), 200)
  }

  createModal() {
    const modal = document.createElement('div')
    modal.id = 'fullscreen-map-modal'
    modal.className = 'fixed inset-0 bg-black/90 z-50 flex items-center justify-center p-4'
    modal.style.zIndex = '9999'
    
    modal.innerHTML = `
      <div class="relative w-full h-full max-w-7xl bg-gray-800 rounded-xl overflow-hidden border border-gold-500/20">
        <div class="absolute top-4 right-4 z-50 flex items-center space-x-3">
          <div class="bg-black/70 text-white px-4 py-2 rounded-lg text-sm">
            <i class="fas fa-map-marker-alt text-gold-500 mr-2"></i>
            <strong>${this.venueNameValue}</strong> - ${this.venueAddressValue}
          </div>
          <button id="close-fullscreen-btn" 
                  class="bg-red-500 hover:bg-red-600 text-white p-3 rounded-lg transition-colors"
                  title="Fermer (Échap)">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div id="fullscreen-map" class="w-full h-full"></div>
      </div>
    `
    
    // Close with X button
    setTimeout(() => {
      const closeBtn = document.getElementById('close-fullscreen-btn')
      if (closeBtn) {
        closeBtn.addEventListener('click', () => this.closeFullscreen())
      }
    }, 100)
    
    // Close with Escape
    const escapeHandler = (e) => {
      if (e.key === 'Escape') {
        this.closeFullscreen()
        document.removeEventListener('keydown', escapeHandler)
      }
    }
    document.addEventListener('keydown', escapeHandler)
    
    // Close by clicking background
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        this.closeFullscreen()
      }
    })
    
    return modal
  }

  initializeFullscreenMap() {
    if (typeof L === 'undefined') {
      return
    }

    const lat = this.latitudeValue || 48.8566
    const lng = this.longitudeValue || 2.3522

    try {
      // Create fullscreen map
      this.fullscreenMap = L.map('fullscreen-map', {
        center: [lat, lng],
        zoom: 16, // Higher zoom for fullscreen
        scrollWheelZoom: true, // Activer le zoom molette
        dragging: true,
        touchZoom: true,
        doubleClickZoom: true
      })

      // Ajouter les tuiles
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 19
      }).addTo(this.fullscreenMap)

      // Larger marker for fullscreen
      const customIcon = L.divIcon({
        className: 'custom-marker-fullscreen',
        html: `
          <div style="
            width: 50px; 
            height: 50px; 
            background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            box-shadow: 0 8px 16px rgba(0,0,0,0.4);
            border: 4px solid white;
            font-size: 20px;
          ">
            📍
          </div>
        `,
        iconSize: [50, 50],
        iconAnchor: [25, 50]
      })

      // Ajouter le marqueur
      const marker = L.marker([lat, lng], { icon: customIcon }).addTo(this.fullscreenMap)
      
      // Detailed popup
      marker.bindPopup(`
        <div style="text-align: center; padding: 16px; min-width: 250px;">
          <h3 style="color: #1f2937; margin: 0 0 12px 0; font-weight: bold; font-size: 18px;">
            🎬 ${this.venueNameValue}
          </h3>
          <p style="color: #6b7280; margin: 0 0 12px 0; font-size: 14px; line-height: 1.4;">
            📍 ${this.venueAddressValue}
          </p>
          <div style="font-size: 12px; color: #9ca3af; padding: 8px; background: #f3f4f6; border-radius: 8px;">
            <strong>Coordonnées:</strong> ${lat.toFixed(4)}, ${lng.toFixed(4)}<br>
            <strong>Zoom:</strong> Molette pour zoomer/dézoomer
          </div>
        </div>
      `).openPopup()

      // Forcer le redimensionnement
      setTimeout(() => {
        this.fullscreenMap.invalidateSize()
      }, 300)

    } catch (error) {
      console.error('❌ Erreur carte plein écran:', error)
    }
  }

  closeFullscreen() {
    const modal = document.getElementById('fullscreen-map-modal')
    if (modal) {
      // Clean up fullscreen map
      if (this.fullscreenMap) {
        this.fullscreenMap.remove()
        this.fullscreenMap = null
      }
      
      // Remove modal
      modal.remove()
      
      // Restaurer le scroll du body
      document.body.style.overflow = ''
      
    }
  }

  showFallback(reason) {
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