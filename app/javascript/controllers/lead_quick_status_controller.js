
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["offerFields"]

  connect() {
    this.toggleFields()
  }

  toggleFields() {
    const statusSelect = this.element.querySelector(
      'select[name="lead[status]"]'
    )

    if (!statusSelect || !this.hasOfferFieldsTarget) return

    this.offerFieldsTarget.hidden = statusSelect.value !== "offer_sent"
  }
}
