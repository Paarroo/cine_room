import { Controller } from "@hotwired/stimulus"

// Cookie consent controller for GDPR compliance
export default class extends Controller {
  static targets = ["banner", "modal"]
  
  connect() {
    this.initializeCookieConsent()
  }

  initializeCookieConsent() {
    // Check if user has already made a choice (check both localStorage and cookies)
    const consentData = this.getCookieConsent()
    const cookieChoice = this.getCookie('cookie_consent')
    
    // If we have localStorage data but no HTTP cookie, sync them
    if (consentData && !cookieChoice) {
      this.saveCookieConsent(consentData)
    }
    // If we have HTTP cookie but no localStorage, recreate localStorage from cookies
    else if (!consentData && cookieChoice === 'true') {
      const syncedData = {
        essential: true,
        analytics: this.getCookie('analytics_consent') === 'true',
        marketing: this.getCookie('marketing_consent') === 'true',
        timestamp: new Date().toISOString(),
        version: '1.0'
      }
      localStorage.setItem('cookieConsent', JSON.stringify(syncedData))
    }
    
    const finalConsentData = this.getCookieConsent()
    
    if (!finalConsentData) {
      // Show banner after a short delay for better UX
      setTimeout(() => {
        this.showBanner()
      }, 1000)
    } else {
      // Apply existing consent preferences
      this.applyCookieSettings(finalConsentData)
    }

    this.bindEventListeners()
  }

  bindEventListeners() {
    // Banner buttons
    document.getElementById('cookie-accept-btn')?.addEventListener('click', () => this.acceptAllCookies())
    document.getElementById('cookie-decline-btn')?.addEventListener('click', () => this.declineAllCookies())
    document.getElementById('cookie-settings-btn')?.addEventListener('click', () => this.showSettings())
    
    // Privacy page button
    document.getElementById('privacy-cookie-settings-btn')?.addEventListener('click', () => this.showSettings())
    
    // Modal buttons
    document.getElementById('cookie-modal-close')?.addEventListener('click', () => this.hideSettings())
    document.getElementById('cookie-save-preferences')?.addEventListener('click', () => this.savePreferences())
    document.getElementById('cookie-accept-all-modal')?.addEventListener('click', () => this.acceptAllFromModal())
    
    // Switch change events for immediate visual feedback
    document.getElementById('analytics-cookies')?.addEventListener('change', (e) => {
      console.log('Analytics cookies toggle:', e.target.checked)
    })
    
    document.getElementById('marketing-cookies')?.addEventListener('change', (e) => {
      console.log('Marketing cookies toggle:', e.target.checked)
    })
    
    // Close modal when clicking outside
    document.getElementById('cookie-settings-modal')?.addEventListener('click', (e) => {
      if (e.target.id === 'cookie-settings-modal') {
        this.hideSettings()
      }
    })
    
    // ESC key to close modal
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        this.hideSettings()
      }
    })
  }

  showBanner() {
    const banner = document.getElementById('cookie-consent-banner')
    if (banner) {
      banner.style.display = 'block'
      // Trigger animation
      setTimeout(() => {
        banner.classList.remove('translate-y-full')
        banner.classList.add('translate-y-0')
      }, 100)
    }
  }

  hideBanner() {
    const banner = document.getElementById('cookie-consent-banner')
    if (banner) {
      banner.classList.add('translate-y-full')
      banner.classList.remove('translate-y-0')
      setTimeout(() => {
        banner.style.display = 'none'
      }, 300)
    }
  }

  showSettings() {
    const modal = document.getElementById('cookie-settings-modal')
    if (modal) {
      modal.style.display = 'flex'
      document.body.classList.add('modal-open')
      document.body.style.overflow = 'hidden'
      
      // Load current preferences
      const consent = this.getCookieConsent()
      if (consent) {
        const analyticsCheckbox = document.getElementById('analytics-cookies')
        const marketingCheckbox = document.getElementById('marketing-cookies')
        
        if (analyticsCheckbox) analyticsCheckbox.checked = consent.analytics || false
        if (marketingCheckbox) marketingCheckbox.checked = consent.marketing || false
      }
      
      // Focus management for accessibility
      const closeButton = document.getElementById('cookie-modal-close')
      if (closeButton) {
        setTimeout(() => closeButton.focus(), 100)
      }
    }
  }

  hideSettings() {
    const modal = document.getElementById('cookie-settings-modal')
    if (modal) {
      modal.style.display = 'none'
      document.body.classList.remove('modal-open')
      document.body.style.overflow = 'auto'
      
      // Return focus to the button that opened the modal
      const settingsButton = document.getElementById('cookie-settings-btn') || 
                            document.getElementById('privacy-cookie-settings-btn')
      if (settingsButton) {
        settingsButton.focus()
      }
    }
  }

  acceptAllCookies() {
    const consentData = {
      essential: true,
      analytics: true,
      marketing: true,
      timestamp: new Date().toISOString(),
      version: '1.0'
    }
    
    this.saveCookieConsent(consentData)
    this.applyCookieSettings(consentData)
    this.hideBanner()
    
    // Show success message
    this.showConsentMessage('Tous les cookies acceptés', 'success')
  }

  declineAllCookies() {
    const consentData = {
      essential: true, // Essential cookies cannot be declined
      analytics: false,
      marketing: false,
      timestamp: new Date().toISOString(),
      version: '1.0'
    }
    
    this.saveCookieConsent(consentData)
    this.applyCookieSettings(consentData)
    this.hideBanner()
    
    // Show success message
    this.showConsentMessage('Préférences de cookies sauvegardées', 'info')
  }

  savePreferences() {
    const analyticsChecked = document.getElementById('analytics-cookies')?.checked || false
    const marketingChecked = document.getElementById('marketing-cookies')?.checked || false
    
    const consentData = {
      essential: true,
      analytics: analyticsChecked,
      marketing: marketingChecked,
      timestamp: new Date().toISOString(),
      version: '1.0'
    }
    
    this.saveCookieConsent(consentData)
    this.applyCookieSettings(consentData)
    this.hideSettings()
    this.hideBanner()
    
    // Show success message
    this.showConsentMessage('Préférences de cookies sauvegardées', 'success')
  }

  acceptAllFromModal() {
    // Update checkboxes
    document.getElementById('analytics-cookies').checked = true
    document.getElementById('marketing-cookies').checked = true
    
    // Save preferences
    this.savePreferences()
  }

  // Cookie management utilities
  saveCookieConsent(consentData) {
    try {
      // Save to localStorage for persistence
      localStorage.setItem('cookieConsent', JSON.stringify(consentData))
      
      // Also set a cookie for server-side access (essential cookies only)
      this.setCookie('cookie_consent', 'true', 365)
      this.setCookie('analytics_consent', consentData.analytics ? 'true' : 'false', 365)
      this.setCookie('marketing_consent', consentData.marketing ? 'true' : 'false', 365)
      
    } catch (error) {
      console.error('Error saving cookie consent:', error)
    }
  }

  getCookieConsent() {
    try {
      const consent = localStorage.getItem('cookieConsent')
      return consent ? JSON.parse(consent) : null
    } catch (error) {
      console.error('Error reading cookie consent:', error)
      return null
    }
  }

  applyCookieSettings(consentData) {
    // Apply analytics cookies
    if (consentData.analytics) {
      this.enableAnalyticsCookies()
    } else {
      this.disableAnalyticsCookies()
    }

    // Apply marketing cookies
    if (consentData.marketing) {
      this.enableMarketingCookies()
    } else {
      this.disableMarketingCookies()
    }
  }

  enableAnalyticsCookies() {
    // Enable Google Analytics or other analytics services
    if (typeof gtag !== 'undefined') {
      gtag('consent', 'update', {
        'analytics_storage': 'granted'
      })
    }
    
    // Add your analytics initialization code here
    console.log('Analytics cookies enabled')
  }

  disableAnalyticsCookies() {
    // Disable analytics tracking
    if (typeof gtag !== 'undefined') {
      gtag('consent', 'update', {
        'analytics_storage': 'denied'
      })
    }
    
    // Remove analytics cookies
    this.removeAnalyticsCookies()
    console.log('Analytics cookies disabled')
  }

  enableMarketingCookies() {
    // Enable marketing/advertising cookies
    if (typeof gtag !== 'undefined') {
      gtag('consent', 'update', {
        'ad_storage': 'granted'
      })
    }
    
    console.log('Marketing cookies enabled')
  }

  disableMarketingCookies() {
    // Disable marketing tracking
    if (typeof gtag !== 'undefined') {
      gtag('consent', 'update', {
        'ad_storage': 'denied'
      })
    }
    
    // Remove marketing cookies
    this.removeMarketingCookies()
    console.log('Marketing cookies disabled')
  }

  removeAnalyticsCookies() {
    // Remove Google Analytics cookies
    const analyticsCookies = ['_ga', '_ga_', '_gid', '_gat', '_gtag_']
    analyticsCookies.forEach(cookieName => {
      this.deleteCookie(cookieName)
      // Also try with domain variants
      this.deleteCookie(cookieName, window.location.hostname)
      this.deleteCookie(cookieName, '.' + window.location.hostname)
    })
  }

  removeMarketingCookies() {
    // Remove common marketing cookies
    const marketingCookies = ['_fbp', '_fbc', 'tr', 'ads']
    marketingCookies.forEach(cookieName => {
      this.deleteCookie(cookieName)
      this.deleteCookie(cookieName, window.location.hostname)
      this.deleteCookie(cookieName, '.' + window.location.hostname)
    })
  }

  // Cookie utility functions
  setCookie(name, value, days) {
    const expires = new Date()
    expires.setTime(expires.getTime() + (days * 24 * 60 * 60 * 1000))
    
    // Add Secure flag for HTTPS
    const isSecure = window.location.protocol === 'https:' ? ';Secure' : ''
    
    document.cookie = `${name}=${value};expires=${expires.toUTCString()};path=/;SameSite=Lax${isSecure}`
  }

  getCookie(name) {
    const nameEQ = name + "="
    const ca = document.cookie.split(';')
    for (let i = 0; i < ca.length; i++) {
      let c = ca[i]
      while (c.charAt(0) === ' ') c = c.substring(1, c.length)
      if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length, c.length)
    }
    return null
  }

  deleteCookie(name, domain = null) {
    const domainAttr = domain ? `;domain=${domain}` : ''
    document.cookie = `${name}=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/${domainAttr}`
  }

  // User feedback
  showConsentMessage(message, type = 'info') {
    // Create a temporary notification
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 z-50 p-4 rounded-lg shadow-lg transition-all duration-300 transform translate-x-full ${
      type === 'success' ? 'bg-green-600' : 
      type === 'error' ? 'bg-red-600' : 'bg-blue-600'
    } text-white`
    
    notification.innerHTML = `
      <div class="flex items-center">
        <i class="fas ${type === 'success' ? 'fa-check-circle' : type === 'error' ? 'fa-exclamation-circle' : 'fa-info-circle'} mr-2"></i>
        <span>${message}</span>
      </div>
    `
    
    document.body.appendChild(notification)
    
    // Animate in
    setTimeout(() => {
      notification.classList.remove('translate-x-full')
      notification.classList.add('translate-x-0')
    }, 100)
    
    // Remove after 3 seconds
    setTimeout(() => {
      notification.classList.add('translate-x-full')
      setTimeout(() => {
        document.body.removeChild(notification)
      }, 300)
    }, 3000)
  }

  // Public method to check if cookies are consented
  static hasConsentFor(type) {
    try {
      const consent = localStorage.getItem('cookieConsent')
      if (!consent) return false
      
      const consentData = JSON.parse(consent)
      return consentData[type] === true
    } catch (error) {
      return false
    }
  }

  // Public method to revoke consent (for settings page)
  static revokeConsent() {
    localStorage.removeItem('cookieConsent')
    // Reload page to show banner again
    window.location.reload()
  }

  // Public method to show settings modal
  static showSettingsModal() {
    const modal = document.getElementById('cookie-settings-modal')
    if (modal) {
      modal.style.display = 'flex'
      document.body.style.overflow = 'hidden'
      
      // Load current preferences
      try {
        const consent = localStorage.getItem('cookieConsent')
        if (consent) {
          const consentData = JSON.parse(consent)
          const analyticsCheckbox = document.getElementById('analytics-cookies')
          const marketingCheckbox = document.getElementById('marketing-cookies')
          
          if (analyticsCheckbox) analyticsCheckbox.checked = consentData.analytics || false
          if (marketingCheckbox) marketingCheckbox.checked = consentData.marketing || false
        }
      } catch (error) {
        console.error('Error loading cookie preferences:', error)
      }
    }
  }
}

// Make methods globally accessible
window.CookieConsentController = {
  showSettings: () => {
    const modal = document.getElementById('cookie-settings-modal')
    if (modal) {
      modal.style.display = 'flex'
      document.body.classList.add('modal-open')
      document.body.style.overflow = 'hidden'
      
      // Load current preferences
      try {
        const consent = localStorage.getItem('cookieConsent')
        if (consent) {
          const consentData = JSON.parse(consent)
          const analyticsCheckbox = document.getElementById('analytics-cookies')
          const marketingCheckbox = document.getElementById('marketing-cookies')
          
          if (analyticsCheckbox) analyticsCheckbox.checked = consentData.analytics || false
          if (marketingCheckbox) marketingCheckbox.checked = consentData.marketing || false
        }
      } catch (error) {
        console.error('Error loading cookie preferences:', error)
      }
      
      // Focus management
      const closeButton = document.getElementById('cookie-modal-close')
      if (closeButton) {
        setTimeout(() => closeButton.focus(), 100)
      }
    }
  },
  
  revokeConsent: () => {
    // Remove localStorage
    localStorage.removeItem('cookieConsent')
    
    // Remove HTTP cookies with all possible domain variations
    const cookies = ['cookie_consent', 'analytics_consent', 'marketing_consent']
    const domains = ['', window.location.hostname, '.' + window.location.hostname]
    
    cookies.forEach(cookieName => {
      domains.forEach(domain => {
        const domainAttr = domain ? `;domain=${domain}` : ''
        document.cookie = `${cookieName}=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/${domainAttr}`
      })
    })
    
    // Also remove third-party cookies
    const thirdPartyCookies = ['_ga', '_ga_', '_gid', '_gat', '_gtag_', '_fbp', '_fbc']
    thirdPartyCookies.forEach(cookieName => {
      domains.forEach(domain => {
        const domainAttr = domain ? `;domain=${domain}` : ''
        document.cookie = `${cookieName}=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/${domainAttr}`
      })
    })
    
    window.location.reload()
  },
  
  hasConsentFor: (type) => {
    try {
      const consent = localStorage.getItem('cookieConsent')
      if (!consent) return false
      
      const consentData = JSON.parse(consent)
      return consentData[type] === true
    } catch (error) {
      return false
    }
  }
}