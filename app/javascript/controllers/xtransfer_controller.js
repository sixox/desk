import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    // Organizations / accounts
    "senderOrganization",
    "senderAccount",
    "receiverOrganization",
    "receiverAccount",

    // Sender
    "senderAmount",
    "senderCurrency",
    "senderExchangeRate",
    "senderToCurrency",
    "senderAmountTo",
    "senderCharge",
    "senderTotal",

    // Receiver
    "receiverAmount",
    "receiverCurrency",
    "receiverExchangeRate",
    "receiverToCurrency",
    "receiverAmountTo",
    "receiverCharge",
    "receiverTotal",

    // Exchanges
    "exchangesContainer",
    "exchangeTemplate"
    ]


  // =========================================================
  // CONNECT
  // =========================================================

  connect() {
    this.updateExchangeButtons()

    // Synchronize receiver currency with sender currencies.
    this.syncReceiverCurrency()

    // Recalculate the complete transfer chain.
    this.updateSenderConversion()
  }


  // =========================================================
  // SENDER ORGANIZATION
  // =========================================================

  loadSenderAccounts(event) {
    const organizationId =
    event.currentTarget.value

    this.loadAccounts(
      organizationId,
      this.senderAccountTarget,
      "sender"
      )
  }


  // =========================================================
  // RECEIVER ORGANIZATION
  // =========================================================

  loadReceiverAccounts(event) {
    const organizationId =
    event.currentTarget.value

    this.loadAccounts(
      organizationId,
      this.receiverAccountTarget,
      "receiver"
      )
  }


  // =========================================================
  // LOAD ACCOUNTS
  //
  // After loading an organization:
  // - automatically select the first account
  // - automatically set its currency
  // =========================================================

  async loadAccounts(
    organizationId,
    accountTarget,
    side = null
    ) {
    if (!organizationId) {
      accountTarget.innerHTML =
      '<option value="">Select account</option>'

      return
    }

    accountTarget.innerHTML =
    '<option value="">Loading accounts...</option>'

    const url =
    `/xtransfers/accounts?organization_id=${encodeURIComponent(
      organizationId
      )}`

    try {
      const response =
      await fetch(
        url,
        {
          method: "GET",
          headers: {
            Accept: "text/html"
          },
          credentials: "same-origin"
        }
        )

      if (!response.ok) {
        throw new Error(
          `HTTP ${response.status}`
          )
      }

      const html =
      await response.text()

      accountTarget.innerHTML =
      html

      // -------------------------------------------------------
      // Automatically select the first real account.
      // -------------------------------------------------------

      const firstAccount =
      Array.from(
        accountTarget.options
        ).find(
        option =>
        option.value &&
        option.value.trim() !== ""
        )

        if (!firstAccount) {
          return
        }

        accountTarget.value =
        firstAccount.value

      // -------------------------------------------------------
      // Automatically set currency from account.
      // -------------------------------------------------------

        if (side === "sender") {
          this.setCurrencyFromAccount(
            accountTarget,
            "sender"
            )
        }

        if (side === "receiver") {
          this.setCurrencyFromAccount(
            accountTarget,
            "receiver"
            )
        }

      } catch (error) {
        console.error(
          "Failed to load accounts:",
          error
          )

        accountTarget.innerHTML =
        '<option value="">Failed to load accounts</option>'
      }
    }


  // =========================================================
  // ACCOUNT -> CURRENCY
  //
  // Reads data-currency-id from selected account.
  // =========================================================

    setCurrencyFromAccount(
      accountTarget,
      side
      ) {
      const option =
      accountTarget.selectedOptions[0]

      if (!option) {
        return
      }

      const currencyId =
      option.dataset.currencyId

      if (!currencyId) {
        return
      }


    // -------------------------------------------------------
    // SENDER ACCOUNT
    // -------------------------------------------------------

      if (
        side === "sender" &&
        this.hasSenderCurrencyTarget
        ) {
        this.senderCurrencyTarget.value =
      currencyId

      // Sender account currency becomes the
      // fallback receiver currency.
      this.syncReceiverCurrency()

      // Recalculate transfer.
      this.updateSenderConversion()

      return
    }


    // -------------------------------------------------------
    // RECEIVER ACCOUNT
    // -------------------------------------------------------

    if (
      side === "receiver" &&
      this.hasReceiverCurrencyTarget
      ) {
      /*
       * Sender To Currency has priority.
       *
       * If it exists:
       *   Receiver Currency = Sender To Currency
       *
       * Otherwise:
       *   Receiver Currency = Sender Currency
       *
       * Only when neither exists:
       *   Receiver account currency is used.
       */

      const senderToCurrency =
    this.hasSenderToCurrencyTarget
    ? this.senderToCurrencyTarget.value
    : ""

    const senderCurrency =
    this.hasSenderCurrencyTarget
    ? this.senderCurrencyTarget.value
    : ""

    if (
      !senderToCurrency &&
      !senderCurrency
      ) {
      this.receiverCurrencyTarget.value =
    currencyId
  }

  this.syncReceiverCurrency()

  this.updateReceiverConversion()
}
}


  // =========================================================
  // SENDER ACCOUNT -> CURRENCY
  // =========================================================

setSenderCurrency(event) {
  const accountTarget =
  event.currentTarget

  this.setCurrencyFromAccount(
    accountTarget,
    "sender"
    )
}


  // =========================================================
  // RECEIVER ACCOUNT -> CURRENCY
  // =========================================================

setReceiverCurrency(event) {
  const accountTarget =
  event.currentTarget

  this.setCurrencyFromAccount(
    accountTarget,
    "receiver"
    )
}


  // =========================================================
  // SYNC RECEIVER CURRENCY
  //
  // Priority:
  //
  // 1. Sender To Currency
  // 2. Sender Currency
  //
  // Receiver account currency is only used when
  // both sender currencies are empty.
  // =========================================================

syncReceiverCurrency() {
  if (!this.hasReceiverCurrencyTarget) {
    return
  }

  let currencyId = ""


    // -------------------------------------------------------
    // First priority: Sender To Currency
    // -------------------------------------------------------

  if (
    this.hasSenderToCurrencyTarget &&
    this.senderToCurrencyTarget.value
    ) {
    currencyId =
  this.senderToCurrencyTarget.value
}


    // -------------------------------------------------------
    // Second priority: Sender Currency
    // -------------------------------------------------------

if (
  !currencyId &&
  this.hasSenderCurrencyTarget &&
  this.senderCurrencyTarget.value
  ) {
  currencyId =
this.senderCurrencyTarget.value
}


    // -------------------------------------------------------
    // Set Receiver Currency
    // -------------------------------------------------------

if (currencyId) {
  this.receiverCurrencyTarget.value =
  currencyId
}
}


  // =========================================================
  // SENDER CURRENCY CHANGED MANUALLY
  //
  // If Sender To Currency exists, it remains the priority.
  // Otherwise Receiver Currency follows Sender Currency.
  // =========================================================

senderCurrencyChanged() {
  this.syncReceiverCurrency()

  this.updateSenderConversion()
}


  // =========================================================
  // SENDER TO CURRENCY CHANGED
  //
  // Sender To Currency immediately becomes
  // Receiver Currency.
  // =========================================================

senderToCurrencyChanged() {
  this.syncReceiverCurrency()

  this.updateSenderConversion()
}


  // =========================================================
  // SENDER CALCULATION
  //
  // Sender Amount
  //       × Sender Exchange Rate
  //       ↓
  // Sender Converted Amount
  //       + Sender Charge (FIXED AMOUNT)
  //       ↓
  // Sender Total
  //       ↓
  // Receiver Amount
  // =========================================================

updateSenderConversion() {
  if (
    !this.hasSenderAmountTarget ||
    !this.hasSenderExchangeRateTarget ||
    !this.hasSenderAmountToTarget ||
    !this.hasSenderTotalTarget
    ) {
    return
}

const amount =
parseFloat(
  this.senderAmountTarget.value
  ) || 0

const rate =
parseFloat(
  this.senderExchangeRateTarget.value
  ) || 0

    // Charge is a FIXED amount.
    //
    // Example:
    // converted amount = 3,670
    // charge = 50
    // total = 3,720
const charge =
this.hasSenderChargeTarget
? parseFloat(
  this.senderChargeTarget.value
  ) || 0
: 0


    // -------------------------------------------------------
    // Empty / zero amount
    // -------------------------------------------------------

if (amount <= 0) {
  this.senderAmountToTarget.value = ""
  this.senderTotalTarget.textContent = "0"

  if (this.hasReceiverAmountTarget) {
    this.receiverAmountTarget.value = ""
  }

  if (this.hasReceiverAmountToTarget) {
    this.receiverAmountToTarget.value = ""
  }

  if (this.hasReceiverTotalTarget) {
    this.receiverTotalTarget.textContent = "0"
  }

  return
}


    // -------------------------------------------------------
    // Sender conversion
    //
    // Amount × Rate
    // -------------------------------------------------------

let calculatedAmount =
amount

if (rate > 0) {
  calculatedAmount =
  amount * rate
}


    // -------------------------------------------------------
    // Sender Converted Amount
    //
    // IMPORTANT:
    // senderAmount remains the original entered amount.
    // senderAmountTo contains the converted amount.
    // -------------------------------------------------------

this.senderAmountToTarget.value =
this.formatNumber(
  calculatedAmount
  )


    // -------------------------------------------------------
    // Sender total
    //
    // Converted Amount + Fixed Charge
    // -------------------------------------------------------

const senderTotal =
calculatedAmount +
charge


this.senderTotalTarget.textContent =
this.formatNumber(senderTotal)


    // -------------------------------------------------------
    // Sender Total -> Receiver Amount
    // -------------------------------------------------------

if (this.hasReceiverAmountTarget) {
  this.receiverAmountTarget.value =
  this.formatNumber(
    senderTotal
    )
}


    // -------------------------------------------------------
    // Keep receiver currency synchronized.
    // -------------------------------------------------------

this.syncReceiverCurrency()


    // -------------------------------------------------------
    // Calculate receiver side.
    // -------------------------------------------------------

this.updateReceiverConversion()
}


  // =========================================================
  // SENDER TOTAL
  // =========================================================

updateSenderTotal() {
  this.updateSenderConversion()
}


  // =========================================================
  // RECEIVER CALCULATION
  //
  // Receiver Amount comes from Sender Total.
  //
  // Receiver Amount
  //       × Receiver Exchange Rate
  //       ↓
  // Receiver Converted Amount
  //       + Receiver Charge (FIXED AMOUNT)
  //       ↓
  // Receiver Total
  // =========================================================

updateReceiverConversion() {
  if (
    !this.hasReceiverAmountTarget ||
    !this.hasReceiverExchangeRateTarget ||
    !this.hasReceiverAmountToTarget
    ) {
    return
}

const amount =
parseFloat(
  this.receiverAmountTarget.value
  ) || 0

const rate =
parseFloat(
  this.receiverExchangeRateTarget.value
  ) || 0


    // -------------------------------------------------------
    // Empty / zero amount
    // -------------------------------------------------------

if (amount <= 0) {
  this.receiverAmountToTarget.value = ""

  if (this.hasReceiverTotalTarget) {
    this.receiverTotalTarget.textContent = "0"
  }

  return
}


    // -------------------------------------------------------
    // Receiver conversion
    //
    // Amount × Rate
    // -------------------------------------------------------

let calculatedAmount =
amount

if (rate > 0) {
  calculatedAmount =
  amount * rate
}


    // -------------------------------------------------------
    // Store calculation information.
    // -------------------------------------------------------

this.receiverAmountTarget.dataset.originalAmount =
amount

this.receiverAmountTarget.dataset.rate =
rate

this.receiverAmountTarget.dataset.calculatedAmount =
this.formatNumber(
  calculatedAmount
  )

this.receiverAmountTarget.dataset.convertedAmount =
this.formatNumber(
  calculatedAmount
  )

this.receiverAmountTarget.dataset.baseAmount =
amount

this.receiverAmountTarget.dataset.receiverConverted =
this.formatNumber(
  calculatedAmount
  )

this.receiverAmountTarget.setAttribute(
  "data-calculated-value",
  this.formatNumber(
    calculatedAmount
    )
  )


    // -------------------------------------------------------
    // Receiver Converted Amount
    //
    // Receiver Amount stays as the original/base amount.
    // Receiver Amount To contains the converted amount.
    // -------------------------------------------------------

this.receiverAmountToTarget.value =
this.formatNumber(
  calculatedAmount
  )


    // -------------------------------------------------------
    // Receiver total
    // -------------------------------------------------------

this.updateReceiverTotal(
  calculatedAmount
  )
}


  // =========================================================
  // RECEIVER TOTAL
  //
  // Receiver Converted Amount
  //       + Receiver Charge (FIXED AMOUNT)
  //       ↓
  // Receiver Total
  // =========================================================

updateReceiverTotal(
  calculatedAmount = null
  ) {
  if (!this.hasReceiverTotalTarget) {
    return
  }


    // -------------------------------------------------------
    // Calculate converted amount if not supplied.
    // -------------------------------------------------------

  if (calculatedAmount === null) {
    const amount =
    this.hasReceiverAmountTarget
    ? parseFloat(
      this.receiverAmountTarget.value
      ) || 0
    : 0

    const rate =
    this.hasReceiverExchangeRateTarget
    ? parseFloat(
      this.receiverExchangeRateTarget.value
      ) || 0
    : 0

    calculatedAmount =
    amount

    if (rate > 0) {
      calculatedAmount =
      amount * rate
    }
  }


    // -------------------------------------------------------
    // Receiver charge is a FIXED amount.
    // -------------------------------------------------------

  const charge =
  this.hasReceiverChargeTarget
  ? parseFloat(
    this.receiverChargeTarget.value
    ) || 0
  : 0


    // -------------------------------------------------------
    // Empty / zero amount
    // -------------------------------------------------------

  if (calculatedAmount <= 0) {
    this.receiverTotalTarget.textContent = "0"

    return
  }


    // -------------------------------------------------------
    // Receiver total
    //
    // Converted Amount + Fixed Charge
    // -------------------------------------------------------

  const receiverTotal =
  calculatedAmount +
  charge


  this.receiverTotalTarget.textContent =
  this.formatNumber(receiverTotal)
}


  // =========================================================
  // FORMAT NUMBER
  //
  // Amounts, totals and converted amounts are integers.
  // Only the exchange rate may be fractional.
  //
  // Any result involving a rate is rounded to the
  // nearest integer before being displayed or written
  // back into a field.
  // =========================================================

formatNumber(value) {
  if (!Number.isFinite(value)) {
    return ""
  }

  return String(Math.round(value))
}


  // =========================================================
  // EXCHANGES
  // =========================================================

addExchange(event) {
  event.preventDefault()

  if (!this.hasExchangeTemplateTarget) {
    return
  }

  const content =
  this.exchangeTemplateTarget.innerHTML

  this.exchangesContainerTarget.insertAdjacentHTML(
    "beforeend",
    content
    )

  this.updateExchangeButtons()
}


removeExchange(event) {
  event.preventDefault()

  const row =
  event.currentTarget.closest(
    ".xt-exchange-row"
    )

  if (!row) {
    return
  }

  const rows =
  this.exchangesContainerTarget.querySelectorAll(
    ".xt-exchange-row"
    )


    // -------------------------------------------------------
    // Keep one row.
    // -------------------------------------------------------

  if (rows.length === 1) {
    const select =
    row.querySelector("select")

    if (select) {
      select.value = ""
    }

    return
  }


  row.remove()

  this.updateExchangeButtons()
}


  // =========================================================
  // EXCHANGE BUTTONS
  // =========================================================

updateExchangeButtons() {
  if (
    !this.hasExchangesContainerTarget
    ) {
    return
}

const rows =
Array.from(
  this.exchangesContainerTarget.querySelectorAll(
    ".xt-exchange-row"
    )
  )


rows.forEach(
  (row, index) => {
    const addButton =
    row.querySelector(
      ".xt-add-exchange"
      )

    if (!addButton) {
      return
    }

    addButton.style.display =
    index === rows.length - 1
    ? "inline-flex"
    : "none"
  }
  )
}
}