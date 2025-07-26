import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["participationItem"]

  connect() {
    console.log("📅 Admin Events controller connected")
  }

  filterParticipations(event) {
    const status = event.target.value
    const items = document.querySelectorAll('.participation-item')
    
    items.forEach(item => {
      if (status === '' || item.dataset.status === status) {
        item.style.display = 'block'
      } else {
        item.style.display = 'none'
      }
    })
  }

  async exportParticipations(event) {
    const eventId = event.params.eventId
    
    try {
      const response = await fetch(`/admin/events/${eventId}/export`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      const data = await response.json()
      
      if (data.success) {
        const link = document.createElement('a')
        link.href = data.download_url
        link.download = data.filename
        link.click()
      }
    } catch (error) {
      console.error('Export error:', error)
    }
  }

  async sendEventNotification(event) {
    const eventId = event.params.eventId
    
    if (!confirm('Envoyer une notification à tous les participants de cet événement ?')) {
      return
    }

    try {
      const response = await fetch(`/admin/events/${eventId}/send_notification`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      const data = await response.json()
      
      if (data.success) {
        alert('Notifications envoyées avec succès !')
      } else {
        alert('Erreur lors de l\'envoi des notifications')
      }
    } catch (error) {
      console.error('Notification error:', error)
    }
  }
}