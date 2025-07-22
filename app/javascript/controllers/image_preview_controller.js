import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "filename", "preview", "image"]

  previewFile() {
    const file = this.inputTarget.files[0]

    if (file) {
      this.filenameTarget.textContent = file.name

      const reader = new FileReader()
      reader.onload = (e) => {
        this.imageTarget.src = e.target.result
        this.previewTarget.classList.remove("hidden")
      }
      reader.readAsDataURL(file)
    } else {
      this.filenameTarget.textContent = "Aucun fichier sélectionné"
      this.previewTarget.classList.add("hidden")
    }
  }
}
