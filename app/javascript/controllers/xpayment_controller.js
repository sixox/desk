import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "senderOrganization",
    "senderAccount",
    "senderInfo",
    "receiverOrganization",
    "receiverAccount",
    "receiverInfo"
  ]

  loadSenderAccounts() {
    this.loadAccounts(
      this.senderOrganizationTarget.value,
      this.senderAccountTarget,
      this.senderInfoTarget
    )
  }

  loadReceiverAccounts() {
    this.loadAccounts(
      this.receiverOrganizationTarget.value,
      this.receiverAccountTarget,
      this.receiverInfoTarget
    )
  }

  async loadAccounts(organizationId, accountTarget, infoTarget) {
    if (!organizationId) {
      accountTarget.innerHTML = '<option value="">Select Account</option>'
      infoTarget.innerHTML = ""
      return
    }

    const response = await fetch(
      `/xpayments/accounts?organization_id=${organizationId}`,
      {
        headers: {
          "Accept": "application/json"
        }
      }
    )

    const accounts = await response.json()

    accountTarget.innerHTML = '<option value="">Select Account</option>'

    accounts.forEach((account) => {
      const option = document.createElement("option")

      option.value = account.id
      option.textContent =
        `${account.number} - ${account.currency_name}`

      accountTarget.appendChild(option)
    })

    if (accounts.length > 0) {
      infoTarget.innerHTML = `
        <div class="small text-secondary mt-2">
          <div><strong>${accounts[0].organization_name}</strong></div>
          <div>${accounts[0].organization_kind || "-"}</div>
          <div>${accounts.length} account(s)</div>
        </div>
      `
    }
  }
}