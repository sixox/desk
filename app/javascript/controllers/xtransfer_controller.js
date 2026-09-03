import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "senderOrganization",
    "senderAccount",
    "receiverOrganization",
    "receiverAccount",
    "exchangesContainer",
    "exchangeTemplate"
  ]

  connect() {
    this.updateExchangeButtons()
  }


  // --------------------------------------------------
  // SENDER / RECEIVER ACCOUNTS
  // --------------------------------------------------

  loadSenderAccounts() {
    this.loadAccounts(
      this.senderOrganizationTarget.value,
      this.senderAccountTarget
    )
  }

  loadReceiverAccounts() {
    this.loadAccounts(
      this.receiverOrganizationTarget.value,
      this.receiverAccountTarget
    )
  }

  async loadAccounts(organizationId, accountTarget) {
    if (!organizationId) {
      accountTarget.innerHTML =
        '<option value="">Select Account</option>'

      return
    }

    const url =
      `/xtransfers/accounts?organization_id=${encodeURIComponent(organizationId)}`

    try {
      const response = await fetch(url, {
        headers: {
          Accept: "text/html"
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

      accountTarget.innerHTML = await response.text()

    } catch (error) {
      console.error("Failed to load accounts:", error)

      accountTarget.innerHTML =
        '<option value="">Failed to load accounts</option>'
    }
  }


  // --------------------------------------------------
  // EXCHANGES
  // --------------------------------------------------

  addExchange(event) {
    event.preventDefault()

    const content = this.exchangeTemplateTarget.innerHTML

    this.exchangesContainerTarget.insertAdjacentHTML(
      "beforeend",
      content
    )

    this.updateExchangeButtons()
  }

  removeExchange(event) {
    event.preventDefault()

    const row =
      event.currentTarget.closest(".xt-exchange-row")

    if (!row) return

    const rows =
      this.exchangesContainerTarget.querySelectorAll(
        ".xt-exchange-row"
      )

    // Keep one exchange row in the form.
    if (rows.length === 1) {
      const select =
        row.querySelector(
          'select[name="xtransfer[exchange_ids][]"]'
        )

      if (select) {
        select.value = ""
      }

      return
    }

    row.remove()

    this.updateExchangeButtons()
  }

  updateExchangeButtons() {
    const rows = Array.from(
      this.exchangesContainerTarget.querySelectorAll(
        ".xt-exchange-row"
      )
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