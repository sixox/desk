import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggleSidebar(event) {
    event.preventDefault()

    const isMobile = window.matchMedia("(max-width: 991.98px)").matches

    if (isMobile) {
      document.body.classList.toggle("sidebar-open")

      const expanded = document.body.classList.contains("sidebar-open")
      this.updateExpandedState(expanded)
    } else {
      document.body.classList.toggle("sidebar-collapsed")
    }
  }

  closeSidebar() {
    document.body.classList.remove("sidebar-open")
    this.updateExpandedState(false)
  }

  closeOnMobile() {
    const isMobile = window.matchMedia("(max-width: 991.98px)").matches

    if (isMobile) {
      this.closeSidebar()
    }
  }

  toggleSubmenu(event) {
    event.preventDefault()

    const link = event.currentTarget
    const parent = link.closest(".has-sub")
    const submenu = parent?.querySelector(":scope > .js-sub-list")

    if (!submenu) return

    const expanded = !link.classList.contains("open")

    link.classList.toggle("open", expanded)
    parent.classList.toggle("open", expanded)

    link.setAttribute("aria-expanded", String(expanded))
    submenu.style.display = expanded ? "block" : "none"
  }

  updateExpandedState(expanded) {
    this.element
      .querySelectorAll(".js-sidebar-toggle[aria-expanded]")
      .forEach((button) => {
        button.setAttribute("aria-expanded", String(expanded))
      })
  }
}