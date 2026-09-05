import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "kind",

    "sellerOrganization",
    "sellerAccount",
    "sellerInfo",

    "buyerOrganization",
    "buyerAccount",
    "buyerInfo",

    "crossCurrencyFields",
    "sameCurrencyFields",
    "currencyExchangeFields",

    "sellCurrency",
    "buyCurrency",
    "exchangeRate",

    "transfersContainer",
    "transferTemplate"
  ]

  connect() {
    if (this.hasKindTarget && this.kindTarget.value) {
      this.changeKind()
    }

    if (this.hasTransfersContainerTarget) {
      this.updateTransferButtons()
    }
  }

  changeKind() {
    const kind = this.kindTarget.value

    this.crossCurrencyFieldsTarget.classList.add("d-none")
    this.sameCurrencyFieldsTarget.classList.add("d-none")
    this.currencyExchangeFieldsTarget.classList.add("d-none")

    if (kind === "cross_currency") {
      this.crossCurrencyFieldsTarget.classList.remove("d-none")
    }

    if (kind === "same_currency") {
      this.sameCurrencyFieldsTarget.classList.remove("d-none")
    }

    if (kind === "currency_exchange") {
      this.currencyExchangeFieldsTarget.classList.remove("d-none")
    }
  }

  loadSellerAccounts() {
    this.loadAccounts(
      this.sellerOrganizationTarget.value,
      this.sellerAccountTarget,
      this.sellerInfoTarget
    )
  }

  loadBuyerAccounts() {
    this.loadAccounts(
      this.buyerOrganizationTarget.value,
      this.buyerAccountTarget,
      this.buyerInfoTarget
    )
  }

  async loadAccounts(organizationId, accountTarget, infoTarget) {
    accountTarget.innerHTML =
      '<option value="">Loading...</option>'

    infoTarget.innerHTML = ""

    if (!organizationId) {
      accountTarget.innerHTML =
        '<option value="">Select Account</option>'
      return
    }

    const response = await fetch(
      `/exchanges/accounts?organization_id=${organizationId}`,
      {
        headers: {
          "Accept": "application/json"
        }
      }
    )

    if (!response.ok) {
      accountTarget.innerHTML =
        '<option value="">Failed to load accounts</option>'
      return
    }

    const accounts = await response.json()

    accountTarget.innerHTML =
      '<option value="">Select Account</option>'

    accounts.forEach((account) => {
      const option = document.createElement("option")

      option.value = account.id
      option.textContent =
        `${account.number} - ${account.currency_name}`

      accountTarget.appendChild(option)
    })

    if (accounts.length > 0) {
      const organization = accounts[0]

      infoTarget.innerHTML = `
        <div class="mt-2 text-secondary small">
          <div>
            <strong>Organization:</strong>
            ${organization.organization_name}
          </div>

          <div>
            <strong>Kind:</strong>
            ${organization.organization_kind || "-"}
          </div>

          <div>
            <strong>Accounts:</strong>
            ${accounts.length}
          </div>
        </div>
      `
    }
  }

  sameCurrencyChanged(event) {
    const currencyId = event.target.value

    if (!currencyId) return

    this.sellCurrencyTarget.value = currencyId
    this.buyCurrencyTarget.value = currencyId

    if (this.hasExchangeRateTarget) {
      this.exchangeRateTarget.value = 1
    }
  }

  // --------------------------------------------------
  // RELATED TRANSFERS
  // --------------------------------------------------

  addTransfer(event) {
    event.preventDefault()

    if (!this.hasTransferTemplateTarget) return
    if (!this.hasTransfersContainerTarget) return

    const content =
      this.transferTemplateTarget.innerHTML

    this.transfersContainerTarget.insertAdjacentHTML(
      "beforeend",
      content
    )

    this.updateTransferButtons()
  }

  removeTransfer(event) {
    event.preventDefault()

    const row =
      event.currentTarget.closest(".xt-exchange-row")

    if (!row) return

    const rows =
      this.transfersContainerTarget.querySelectorAll(
        ".xt-exchange-row"
      )

    if (rows.length === 1) {
      const select = row.querySelector("select")

      if (select) {
        select.value = ""
      }

      return
    }

    row.remove()

    this.updateTransferButtons()
  }

  updateTransferButtons() {
    if (!this.hasTransfersContainerTarget) return

    const rows =
      this.transfersContainerTarget.querySelectorAll(
        ".xt-exchange-row"
      )

    rows.forEach((row, index) => {
      const addButton =
        row.querySelector(".xt-add-exchange")

      const removeButton =
        row.querySelector(".xt-remove-exchange")

      if (addButton) {
        addButton.classList.toggle(
          "d-none",
          index !== rows.length - 1
        )
      }

      if (removeButton) {
        removeButton.classList.toggle(
          "d-none",
          rows.length === 1
        )
      }
    })
  }
}