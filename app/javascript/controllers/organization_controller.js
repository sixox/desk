import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "accountsContainer",
    "accountTemplate"
  ]

  connect() {
    this.updateAccountButtons()
  }

  // --------------------------------------------------
  // ACCOUNTS
  // --------------------------------------------------

  addAccount(event) {
    event.preventDefault()

    let content = this.accountTemplateTarget.innerHTML

    // Replace the placeholder index with a unique timestamp so
    // every added row gets its own key in the params hash.
    const uniqueIndex = new Date().getTime().toString()
    content = content.replace(/NEW_RECORD/g, uniqueIndex)

    this.accountsContainerTarget.insertAdjacentHTML(
      "beforeend",
      content
    )

    this.updateAccountButtons()
  }

  removeAccount(event) {
    event.preventDefault()

    const row =
      event.currentTarget.closest(".xt-exchange-row")

    if (!row) return

    const rows =
      this.accountsContainerTarget.querySelectorAll(
        ".xt-exchange-row"
      )

    // Keep one account row in the form.
    if (rows.length === 1) {
      const inputs =
        row.querySelectorAll(
          "input:not([type=hidden]), select"
        )

      inputs.forEach((input) => {
        input.value = ""
      })

      return
    }

    // Existing/persisted account
    const destroyField =
      row.querySelector(
        'input[name*="_destroy"]'
      )

    if (destroyField) {
      destroyField.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }

    this.updateAccountButtons()
  }

  updateAccountButtons() {
    const rows = Array.from(
      this.accountsContainerTarget.querySelectorAll(
        ".xt-exchange-row"
      )
    ).filter(
      (row) => row.style.display !== "none"
    )

    rows.forEach((row, index) => {

      const addButton =
        row.querySelector(".xt-add-exchange")

      if (!addButton) return

      addButton.style.display =
        index === rows.length - 1
          ? "inline-flex"
          : "none"
    })
  }
}