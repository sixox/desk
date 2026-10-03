import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "exchangesContainer",
    "exchangeTemplate"
  ]


  connect() {
    this.updateExchangeButtons()
  }


  // =========================================================
  // ADD EXCHANGE
  // =========================================================

  addExchange(event) {
    event.preventDefault()

    if (
      !this.hasExchangeTemplateTarget ||
      !this.hasExchangesContainerTarget
    ) {
      return
    }


    const index =
      this.newIndex()


    const content =
      this.exchangeTemplateTarget.innerHTML
        .replaceAll(
          "NEW_RECORD",
          index
        )


    this.exchangesContainerTarget.insertAdjacentHTML(
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


    const idField =
      row.querySelector(
        'input[name*="[id]"]'
      )


    const destroyField =
      row.querySelector(
        'input[name*="[_destroy]"]'
      )


    /*
     * Persisted ExchangeTransfer.
     */

    if (
      idField &&
      idField.value &&
      destroyField
    ) {

      destroyField.value =
        "1"

      row.style.display =
        "none"

      this.updateExchangeButtons()

      return
    }


    /*
     * New unsaved row.
     */

    row.remove()

    this.updateExchangeButtons()
  }


  // =========================================================
  // BUTTONS
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
      .filter(
        row =>
          row.style.display !== "none"
      )


    rows.forEach(
      (row, index) => {

        const addButton =
          row.querySelector(
            ".xt-add-exchange"
          )


        if (addButton) {

          addButton.style.display =
            index === rows.length - 1
              ? "inline-flex"
              : "none"
        }
      }
    )
  }


  // =========================================================
  // INDEX
  // =========================================================

  newIndex() {
    return (
      Date.now().toString() +
      "_" +
      Math.random()
        .toString(36)
        .substring(2, 8)
    )
  }
}