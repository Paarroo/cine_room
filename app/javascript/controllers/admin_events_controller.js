<script>
// Event management functions
function filterParticipations(status) {
  const items = document.querySelectorAll('.participation-item');
  items.forEach(item => {
    if (status === '' || item.dataset.status === status) {
      item.style.display = 'block';
    } else {
      item.style.display = 'none';
    }
  });
}

function exportParticipations(eventId) {
  // Implementation for exporting participations
  fetch(`/admin/events/${eventId}/export_participations`, {
    method: 'GET',
    headers: {
      'Accept': 'application/json',
      'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
    }
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      // Trigger download
      const link = document.createElement('a');
      link.href = data.download_url;
      link.download = data.filename;
      link.click();
    }
  })
  .catch(error => console.error('Export error:', error));
}

function sendEventNotification(eventId) {
  if (!confirm('Envoyer une notification à tous les participants de cet événement ?')) {
    return;
  }

  // Implementation for sending notifications
  fetch(`/admin/events/${eventId}/send_notification`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
    }
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      alert('Notifications envoyées avec succès !');
    } else {
      alert('Erreur lors de l\'envoi des notifications');
    }
  })
  .catch(error => console.error('Notification error:', error));
}
</script>
