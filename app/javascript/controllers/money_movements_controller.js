import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "sendContainer",
    "receiveContainer",
    "sendTemplate",
    "receiveTemplate"
    ]

  connect() {
    this.recalculateAll()
  }


  // ==================================================
  // ADD SEND
  // ==================================================

  addSend(event) {
    event.preventDefault()

    this.addMovement(
      "send"
      )
  }


  // ==================================================
  // ADD RECEIVE
  // ==================================================

  addReceive(event) {
    event.preventDefault()

    this.addMovement(
      "receive"
      )
  }

// ==================================================
// ADD MOVEMENT
// ==================================================

  addMovement(direction) {
    const template =
    direction === "send"
    ? this.sendTemplateTarget
    : this.receiveTemplateTarget

    const container =
    direction === "send"
    ? this.sendContainerTarget
    : this.receiveContainerTarget

    const index =
    Date.now().toString() +
    Math.floor(
      Math.random() * 1000
      ).toString()

    const html =
    template.innerHTML.replace(
      /NEW_RECORD/g,
      index
      )

    container.insertAdjacentHTML(
      "beforeend",
      html
      )

    this.recalculateAll()
  }

  // ==================================================
  // REMOVE
  // ==================================================

  removeMovement(event) {
    event.preventDefault()


    const row =
    event.currentTarget.closest(
      "[data-movement-row]"
      )


    if (!row) {
      return
    }


    const idField =
    row.querySelector(
      'input[name*="[id]"]'
      )


    const destroyField =
    row.querySelector(
      'input[name*="_destroy"]'
      )


    if (
      idField &&
      idField.value
      ) {

      if (destroyField) {
        destroyField.value = "1"
      }

      row.classList.add(
        "d-none"
        )

    } else {

      row.remove()
    }


    this.ensureAtLeastOneMovement(
      "send"
      )

    this.ensureAtLeastOneMovement(
      "receive"
      )

    this.recalculateAll()
  }


  // ==================================================
  // ORGANIZATION -> ACCOUNTS
  // ==================================================

  async loadAccounts(event) {
    const organizationId =
    event.currentTarget.value


    const row =
    event.currentTarget.closest(
      "[data-movement-row]"
      )


    if (!row) {
      return
    }


    const accountSelect =
    row.querySelector(
      "[data-account-select]"
      )


    if (!accountSelect) {
      return
    }


    accountSelect.innerHTML =
    '<option value="">Loading...</option>'

    accountSelect.disabled = true


    if (!organizationId) {

      accountSelect.innerHTML =
      '<option value="">Select account</option>'

      accountSelect.disabled = false

      return
    }


    const url =
    new URL(
      this.element.dataset.accountsUrl,
      window.location.origin
      )


    url.searchParams.set(
      "organization_id",
      organizationId
      )


    try {

      const response =
      await fetch(
        url,
        {
          headers: {
            Accept: "application/json"
          }
        }
        )


      if (!response.ok) {
        throw new Error(
          `HTTP ${response.status}`
          )
      }


      const accounts =
      await response.json()


      accountSelect.innerHTML =
      '<option value="">Select account</option>'


      accounts.forEach(account => {

        const option =
        document.createElement(
          "option"
          )


        option.value =
        account.id


        option.textContent =
        `${account.number} - ${
          account.currency_name || "—"
        }`


        option.dataset.currencyId =
        account.currency_id


        option.dataset.currencyName =
        account.currency_name || ""


        accountSelect.appendChild(
          option
          )
      })


      accountSelect.disabled = false


      if (
        accounts.length === 1
        ) {

        accountSelect.value =
      accounts[0].id


      this.setAccountCurrency({
        currentTarget: accountSelect
      })
    }

  } catch (error) {

    console.error(
      "Unable to load accounts:",
      error
      )


    accountSelect.innerHTML =
    '<option value="">Unable to load accounts</option>'


    accountSelect.disabled = false
  }
}


  // ==================================================
  // ACCOUNT -> CURRENCY
  // ==================================================

setAccountCurrency(event) {
  const accountSelect =
  event.currentTarget


  const row =
  accountSelect.closest(
    "[data-movement-row]"
    )


  if (!row) {
    return
  }


  const option =
  accountSelect.options[
    accountSelect.selectedIndex
    ]


  if (!option) {
    return
  }


  const currencySelect =
  row.querySelector(
    "[data-currency-select]"
    )


  if (
    currencySelect &&
    option.dataset.currencyId
    ) {

    currencySelect.value =
  option.dataset.currencyId
}


this.recalculateRow(
  row
  )
}


  // ==================================================
  // RECALCULATE ALL
  // ==================================================

recalculateAll() {
  this.element
  .querySelectorAll(
    "[data-movement-row]"
    )
  .forEach(row => {

    this.recalculateRow(
      row
      )
  })
}


  // ==================================================
  // RECALCULATE ROW
  // ==================================================

recalculateRow(eventOrRow) {

  const row =
  eventOrRow instanceof Element
  ? eventOrRow
  : eventOrRow.currentTarget?.closest(
    "[data-movement-row]"
    )


  if (!row) {
    return
  }


  const amountInput =
  row.querySelector(
    "[data-amount]"
    )


  const rateInput =
  row.querySelector(
    "[data-exchange-rate]"
    )


  const amountToInput =
  row.querySelector(
    "[data-amount-to]"
    )


  const chargeInput =
  row.querySelector(
    "[data-charge]"
    )


  const totalInput =
  row.querySelector(
    "[data-total]"
    )


  const totalDisplay =
  row.querySelector(
    "[data-total-display]"
    )


  if (
    !amountInput ||
    !amountToInput
    ) {
    return
}


const amount =
this.numberValue(
  amountInput.value
  )


const rate =
rateInput
? this.numberValue(
  rateInput.value
  )
: 0


const charge =
chargeInput
? this.numberValue(
  chargeInput.value
  )
: 0


const amountTo =
rate > 0
? amount * rate
: amount


const roundedAmountTo =
this.round(
  amountTo,
  5
  )


const total =
this.round(
  roundedAmountTo + charge,
  5
  )


amountToInput.value =
this.format(
  roundedAmountTo
  )


if (totalInput) {

  totalInput.value =
  this.format(
    total
    )
}


if (totalDisplay) {

  totalDisplay.textContent =
  this.format(
    total
    )
}
}


  // ==================================================
  // ENSURE AT LEAST ONE
  // ==================================================

ensureAtLeastOneMovement(
  direction
  ) {

  const container =
  direction === "send"
  ? this.sendContainerTarget
  : this.receiveContainerTarget


  const visibleRows =
  Array.from(
    container.querySelectorAll(
      "[data-movement-row]"
      )
    ).filter(
    row =>
    !row.classList.contains(
      "d-none"
      )
    )


    if (
      visibleRows.length === 0
      ) {

      this.addMovement(
        direction
        )
  }
}


  // ==================================================
  // NUMBER
  // ==================================================

numberValue(value) {
  const number =
  parseFloat(
    value
    )


  return Number.isFinite(
    number
    )
  ? number
  : 0
}


  // ==================================================
  // ROUND
  // ==================================================

round(
  value,
  decimals = 5
  ) {

  const factor =
  Math.pow(
    10,
    decimals
    )


  return Math.round(
    value * factor
    ) / factor
}


  // ==================================================
  // FORMAT
  // ==================================================

format(value) {

  return this.round(
    value,
    5
    ).toString()
}
}