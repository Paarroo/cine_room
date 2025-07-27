import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    movieId: Number,
    favorited: Boolean,
    favoriteId: Number
  }

  connect() {
  }

  async toggle() {
    // Prevent event bubbling to avoid card click
    event.preventDefault()
    event.stopPropagation()

    if (this.favoritedValue) {
      await this.removeFavorite()
    } else {
      await this.addFavorite()
    }
  }

  async addFavorite() {
    try {
      const response = await fetch('/favorites', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ movie_id: this.movieIdValue })
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const result = await response.json()
      
      if (result.status === 'success') {
        this.favoriteIdValue = result.favorite_id
        this.favoritedValue = true
        this.updateUI(true, result.count)
        this.showToast(result.message, 'success')
      } else {
        throw new Error(result.message || 'Erreur lors de l\'ajout aux favoris')
      }
    } catch (error) {
      console.error('Add favorite error:', error)
      this.showToast(error.message || 'Erreur de connexion', 'error')
    }
  }

  async removeFavorite() {
    if (!this.favoriteIdValue) {
      console.error('No favorite ID to remove')
      return
    }

    try {
      const response = await fetch(`/favorites/${this.favoriteIdValue}`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const result = await response.json()
      
      if (result.status === 'success') {
        this.favoriteIdValue = null
        this.favoritedValue = false
        this.updateUI(false, result.count)
        this.showToast(result.message, 'success')
      } else {
        throw new Error(result.message || 'Erreur lors de la suppression des favoris')
      }
    } catch (error) {
      console.error('Remove favorite error:', error)
      this.showToast(error.message || 'Erreur de connexion', 'error')
    }
  }

  updateUI(favorited, count) {
    const icon = this.element.querySelector('i')
    const countSpan = this.element.querySelector('.favorites-count')
    
    // Update heart icon
    if (icon) {
      icon.className = favorited ? 'fas fa-heart text-sm' : 'far fa-heart text-sm'
    }
    
    // Update count if element exists
    if (countSpan && count !== undefined) {
      countSpan.textContent = count
      countSpan.style.display = count > 0 ? 'flex' : 'none'
    }
    
    // Update button appearance
    this.element.classList.toggle('favorited', favorited)
    
    // Add animation
    this.element.classList.add('animate-pulse')
    setTimeout(() => {
      this.element.classList.remove('animate-pulse')
    }, 300)

    // Scale animation on heart
    if (icon) {
      icon.style.transform = 'scale(1.2)'
      setTimeout(() => {
        icon.style.transform = 'scale(1)'
      }, 200)
    }
  }

  getCSRFToken() {
    const token = document.querySelector('[name="csrf-token"]')
    return token ? token.content : ''
  }

  showToast(message, type = 'info') {
    // Create simple toast notification
    const toast = document.createElement('div')
    toast.className = `fixed top-20 right-6 z-50 px-4 py-2 rounded-lg text-white font-medium transition-all duration-300 transform translate-x-full`
    
    switch (type) {
      case 'success':
        toast.classList.add('bg-green-500')
        break
      case 'error':
        toast.classList.add('bg-red-500')
        break
      default:
        toast.classList.add('bg-blue-500')
    }
    
    toast.textContent = message
    document.body.appendChild(toast)
    
    // Animate in
    setTimeout(() => {
      toast.classList.remove('translate-x-full')
    }, 100)
    
    // Animate out and remove
    setTimeout(() => {
      toast.classList.add('translate-x-full')
      setTimeout(() => {
        if (toast.parentNode) {
          toast.parentNode.removeChild(toast)
        }
      }, 300)
    }, 3000)
  }
}