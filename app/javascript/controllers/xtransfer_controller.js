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

  connect() {
    this.senderAccountsRequestId = 0
    this.receiverAccountsRequestId = 0

    this.updateExchangeButtons()
    this.syncReceiverCurrency()
    this.recalculate()
  }


  // =========================================================
  // MASTER CALCULATION
  // =========================================================

  recalculate() {
    this.updateSenderConversion()
  }


  // =========================================================
  // SENDER ORGANIZATION
  // =========================================================

  loadSenderAccounts(event) {
    const organizationId = event.currentTarget.value

    this.loadAccounts(
      organizationId,
      "sender"
    )
  }


  // =========================================================
  // RECEIVER ORGANIZATION
  // =========================================================

  loadReceiverAccounts(event) {
    const organizationId = event.currentTarget.value

    this.loadAccounts(
      organizationId,
      "receiver"
    )
  }


  // =========================================================
  // LOAD ACCOUNTS
  // =========================================================

  async loadAccounts(
    organizationId,
    side
  ) {
    const accountTarget =
      side === "sender"
        ? this.senderAccountTarget
        : this.receiverAccountTarget

    if (!accountTarget) {
      return
    }


    // -------------------------------------------------------
    // Request ID prevents an old/slow request from replacing
    // the accounts from a newer organization selection.
    // -------------------------------------------------------

    const requestId =
      side === "sender"
        ? ++this.senderAccountsRequestId
        : ++this.receiverAccountsRequestId


    // -------------------------------------------------------
    // No organization selected
    // -------------------------------------------------------

    if (!organizationId) {
      accountTarget.innerHTML =
        '<option value="">Select account</option>'

      this.clearAccountCurrency(side)

      return
    }


    // -------------------------------------------------------
    // Loading state
    // -------------------------------------------------------

    accountTarget.innerHTML =
      '<option value="">Loading accounts...</option>'

    accountTarget.disabled = true


    const url =
      `/xtransfers/accounts?organization_id=${encodeURIComponent(
        organizationId
      )}`


    try {
      const response =
        await fetch(url, {
          method: "GET",
          headers: {
            Accept: "text/html"
          },
          credentials: "same-origin"
        })


      if (!response.ok) {
        throw new Error(
          `HTTP ${response.status}`
        )
      }


      const html =
        await response.text()


      // -----------------------------------------------------
      // Ignore this response if another request was started
      // after this one.
      // -----------------------------------------------------

      const currentRequestId =
        side === "sender"
          ? this.senderAccountsRequestId
          : this.receiverAccountsRequestId

      if (requestId !== currentRequestId) {
        return
      }


      accountTarget.innerHTML =
        html


      accountTarget.disabled = false


      // -----------------------------------------------------
      // Find first real account.
      // -----------------------------------------------------

      const firstAccount =
        Array.from(
          accountTarget.options
        ).find(
          option =>
            option.value &&
            option.value.trim() !== ""
        )


      if (!firstAccount) {
        this.clearAccountCurrency(side)
        return
      }


      // -----------------------------------------------------
      // Automatically select first account.
      // -----------------------------------------------------

      accountTarget.value =
        firstAccount.value


      this.setCurrencyFromAccount(
        accountTarget,
        side
      )

    } catch (error) {

      console.error(
        "Failed to load accounts:",
        error
      )


      // -----------------------------------------------------
      // Don't overwrite a newer request.
      // -----------------------------------------------------

      const currentRequestId =
        side === "sender"
          ? this.senderAccountsRequestId
          : this.receiverAccountsRequestId

      if (requestId !== currentRequestId) {
        return
      }


      accountTarget.innerHTML =
        '<option value="">Failed to load accounts</option>'

      accountTarget.disabled = false

      this.clearAccountCurrency(side)
    }
  }


  // =========================================================
  // ACCOUNT -> CURRENCY
  // =========================================================

  setCurrencyFromAccount(
    accountTarget,
    side
  ) {
    if (!accountTarget) {
      return
    }


    const option =
      accountTarget.selectedOptions[0]


    if (!option) {
      this.clearAccountCurrency(side)
      return
    }


    const currencyId =
      option.dataset.currencyId


    if (!currencyId) {
      this.clearAccountCurrency(side)
      return
    }


    if (
      side === "sender" &&
      this.hasSenderCurrencyTarget
    ) {
      this.senderCurrencyTarget.value =
        currencyId

      this.syncReceiverCurrency()
      this.updateSenderConversion()

      return
    }


    if (
      side === "receiver" &&
      this.hasReceiverCurrencyTarget
    ) {
      /*
       * Sender conversion controls receiver currency
       * when sender currency / sender To Currency exists.
       *
       * Otherwise use the receiver account currency.
       */

      if (
        !this.hasSenderCurrencyTarget ||
        !this.senderCurrencyTarget.value
      ) {
        this.receiverCurrencyTarget.value =
          currencyId
      }


      this.syncReceiverCurrency()
      this.updateReceiverConversion()
    }
  }


  // =========================================================
  // CLEAR ACCOUNT CURRENCY
  // =========================================================

  clearAccountCurrency(side) {
    if (
      side === "sender" &&
      this.hasSenderCurrencyTarget
    ) {
      this.senderCurrencyTarget.value = ""
    }


    if (
      side === "receiver" &&
      this.hasReceiverCurrencyTarget
    ) {
      this.receiverCurrencyTarget.value = ""
    }
  }


  // =========================================================
  // SENDER ACCOUNT -> CURRENCY
  // =========================================================

  setSenderCurrency(event) {
    this.setCurrencyFromAccount(
      event.currentTarget,
      "sender"
    )
  }


  // =========================================================
  // RECEIVER ACCOUNT -> CURRENCY
  // =========================================================

  setReceiverCurrency(event) {
    this.setCurrencyFromAccount(
      event.currentTarget,
      "receiver"
    )
  }


  // =========================================================
  // RECEIVER CURRENCY SYNCHRONIZATION
  //
  // Priority:
  //
  // 1. Sender To Currency
  // 2. Sender Currency
  // =========================================================

  syncReceiverCurrency() {
    if (!this.hasReceiverCurrencyTarget) {
      return
    }


    let currencyId = ""


    if (
      this.hasSenderToCurrencyTarget &&
      this.senderToCurrencyTarget.value
    ) {
      currencyId =
        this.senderToCurrencyTarget.value
    }


    if (
      !currencyId &&
      this.hasSenderCurrencyTarget &&
      this.senderCurrencyTarget.value
    ) {
      currencyId =
        this.senderCurrencyTarget.value
    }


    if (currencyId) {
      this.receiverCurrencyTarget.value =
        currencyId
    }
  }


  // =========================================================
  // SENDER CURRENCY CHANGED
  // =========================================================

  senderCurrencyChanged() {
    this.syncReceiverCurrency()
    this.updateSenderConversion()
  }


  // =========================================================
  // SENDER TO CURRENCY CHANGED
  // =========================================================

  senderToCurrencyChanged() {
    this.syncReceiverCurrency()
    this.updateSenderConversion()
  }


  // =========================================================
  // SENDER CALCULATION
  //
  // Amount × Rate
  //       ↓
  // Sender Amount To
  //       + Charge
  //       ↓
  // Sender Total
  //       ↓
  // Receiver Amount
  // =========================================================

  updateSenderConversion() {
    if (
      !this.hasSenderAmountTarget ||
      !this.hasSenderAmountToTarget
    ) {
      return
    }


    const amount =
      this.numberValue(
        this.senderAmountTarget.value
      )


    const rate =
      this.hasSenderExchangeRateTarget
        ? this.numberValue(
            this.senderExchangeRateTarget.value
          )
        : 0


    const charge =
      this.hasSenderChargeTarget
        ? this.numberValue(
            this.senderChargeTarget.value
          )
        : 0


    // -------------------------------------------------------
    // Empty / zero amount
    // -------------------------------------------------------

    if (amount <= 0) {

      this.senderAmountToTarget.value = ""


      if (this.hasSenderTotalTarget) {
        this.senderTotalTarget.textContent = "0"
      }


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
    // BOTH sides use multiplication.
    //
    // Sender:
    //
    // 1000 × 3.67 = 3670
    // -------------------------------------------------------

    const converted =
      rate > 0
        ? Math.round(
            amount * rate
          )
        : Math.round(amount)


    const senderTotal =
      converted + charge


    // -------------------------------------------------------
    // Sender Amount To
    // -------------------------------------------------------

    this.senderAmountToTarget.value =
      this.formatNumber(converted)


    // -------------------------------------------------------
    // Sender Total
    // -------------------------------------------------------

    if (this.hasSenderTotalTarget) {

      this.senderTotalTarget.textContent =
        this.formatNumber(
          senderTotal
        )

    }


    // -------------------------------------------------------
    // Sender total becomes receiver amount.
    // -------------------------------------------------------

    if (this.hasReceiverAmountTarget) {

      this.receiverAmountTarget.value =
        this.formatNumber(
          senderTotal
        )

    }


    this.syncReceiverCurrency()

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
  // IMPORTANT:
  //
  // Receiver Amount × Receiver Rate
  //
  // Example:
  //
  // 3670 × 0.258856... = 950
  //
  // BOTH exchange rates multiply.
  // =========================================================

  updateReceiverConversion() {
    if (
      !this.hasReceiverAmountTarget ||
      !this.hasReceiverAmountToTarget
    ) {
      return
    }


    const amount =
      this.numberValue(
        this.receiverAmountTarget.value
      )


    const rate =
      this.hasReceiverExchangeRateTarget
        ? this.numberValue(
            this.receiverExchangeRateTarget.value
          )
        : 0


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
    // amount × rate
    // -------------------------------------------------------

    const converted =
      rate > 0
        ? Math.round(
            amount * rate
          )
        : Math.round(amount)


    // -------------------------------------------------------
    // Receiver Amount To
    // -------------------------------------------------------

    this.receiverAmountToTarget.value =
      this.formatNumber(
        converted
      )


    this.updateReceiverTotal(
      converted
    )
  }


  // =========================================================
  // RECEIVER TOTAL
  // =========================================================

  updateReceiverTotal(
    calculatedAmount = null
  ) {
    if (!this.hasReceiverTotalTarget) {
      return
    }


    if (calculatedAmount === null) {

      const amount =
        this.hasReceiverAmountTarget
          ? this.numberValue(
              this.receiverAmountTarget.value
            )
          : 0


      const rate =
        this.hasReceiverExchangeRateTarget
          ? this.numberValue(
              this.receiverExchangeRateTarget.value
            )
          : 0


      // IMPORTANT:
      // multiplication, not division

      calculatedAmount =
        rate > 0
          ? Math.round(
              amount * rate
            )
          : Math.round(amount)

    }


    const charge =
      this.hasReceiverChargeTarget
        ? this.numberValue(
            this.receiverChargeTarget.value
          )
        : 0


    if (calculatedAmount <= 0) {

      this.receiverTotalTarget.textContent =
        "0"

      return
    }


    const total =
      calculatedAmount +
      charge


    this.receiverTotalTarget.textContent =
      this.formatNumber(
        total
      )
  }


  // =========================================================
  // RECEIVER TOTAL DIRECT UPDATE
  // =========================================================

  receiverChargeChanged() {
    this.updateReceiverConversion()
  }


  // =========================================================
  // NUMBER HELPERS
  // =========================================================

  numberValue(value) {
    if (
      value === null ||
      value === undefined ||
      value === ""
    ) {
      return 0
    }


    // -------------------------------------------------------
    // Remove commas and spaces.
    // This allows:
    //
    // 1,000
    // 3 670
    // -------------------------------------------------------

    const normalized =
      String(value)
        .replaceAll(",", "")
        .replaceAll(" ", "")
        .trim()


    const number =
      parseFloat(
        normalized
      )


    return Number.isFinite(number)
      ? number
      : 0
  }


  formatNumber(value) {
    if (!Number.isFinite(value)) {
      return ""
    }


    return String(
      Math.round(value)
    )
  }


  // =========================================================
  // EXCHANGES
  // =========================================================

  addExchange(event) {
    event.preventDefault()


    if (!this.hasExchangeTemplateTarget) {
      return
    }


    if (!this.hasExchangesContainerTarget) {
      return
    }


    const index =
      this.newExchangeIndex()


    const content =
      this.exchangeTemplateTarget.innerHTML
        .replaceAll(
          "NEW_RECORD",
          index
        )


    this.exchangesContainerTarget
      .insertAdjacentHTML(
        "beforeend",
        content
      )


    this.updateExchangeButtons()
  }


  // =========================================================
  // REMOVE EXCHANGE
  // =========================================================

  removeExchange(event) {
    event.preventDefault()


    const row =
      event.currentTarget.closest(
        ".xt-exchange-row"
      )


    if (!row) {
      return
    }


    // -------------------------------------------------------
    // Existing persisted association:
    //
    // Set _destroy = 1 instead of removing it directly.
    // -------------------------------------------------------

    const destroyField =
      row.querySelector(
        'input[name*="[_destroy]"]'
      )


    const idField =
      row.querySelector(
        'input[name*="[id]"]'
      )


    if (
      destroyField &&
      idField &&
      idField.value
    ) {

      destroyField.value = "1"

      row.style.display = "none"

      this.updateExchangeButtons()

      return
    }


    // -------------------------------------------------------
    // New unsaved association.
    // -------------------------------------------------------

    row.remove()

    this.updateExchangeButtons()
  }


  // =========================================================
  // UNIQUE EXCHANGE INDEX
  // =========================================================

  newExchangeIndex() {
    return (
      Date.now().toString() +
      Math.floor(
        Math.random() * 100000
      ).toString()
    )
  }


  // =========================================================
  // EXCHANGE BUTTONS
  // =========================================================

  updateExchangeButtons() {
    if (!this.hasExchangesContainerTarget) {
      return
    }

    /*
     * Kept intentionally.
     *
     * Your existing markup can continue using the
     * current global Add Exchange button.
     */
  }
}