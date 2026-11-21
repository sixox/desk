
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "piEditor",
    "ciCreate",
    "bookingCreate"
  ]

  togglePi() {
    if (this.hasPiEditorTarget) {
      this.toggleEditor(this.piEditorTarget)
    }
  }

  toggleCi() {
    if (this.hasCiCreateTarget) {
      this.toggleEditor(this.ciCreateTarget)
    }
  }

  toggleBooking() {
    if (this.hasBookingCreateTarget) {
      this.toggleEditor(this.bookingCreateTarget)
    }
  }

  toggleEditor(target) {
    target.open = !target.open

    if (target.open) {
      requestAnimationFrame(() => {
        target.scrollIntoView({
          behavior: "smooth",
          block: "center"
        })
      })
    }
  }
}
