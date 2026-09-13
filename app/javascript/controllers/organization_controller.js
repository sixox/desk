import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "accountsContainer",
    "accountTemplate",
    "accountCount"
  ]


  // --------------------------------------------------
  // CONNECT
  // --------------------------------------------------

  connect() {
    this.updateAccountButtons()
    this.updateAccountCount()
  }


  // --------------------------------------------------
  // ADD ACCOUNT
  // --------------------------------------------------

  addAccount(event) {
    event.preventDefault()

    let content = this.accountTemplateTarget.innerHTML

    const uniqueIndex =
      `${Date.now()}_${Math.random().toString(36).substring(2, 8)}`

    content = content.replace(
      /NEW_RECORD/g,
      uniqueIndex
    )

    this.accountsContainerTarget.insertAdjacentHTML(
      "beforeend",
      content
    )

    this.updateAccountButtons()
    this.updateAccountCount()
  }


  // --------------------------------------------------
  // REMOVE ACCOUNT
  // --------------------------------------------------

  removeAccount(event) {
    event.preventDefault()

    const row =
      event.currentTarget.closest(".xt-exchange-row")

    if (!row) return


    const rows =
      Array.from(
        this.accountsContainerTarget.querySelectorAll(
          ".xt-exchange-row"
        )
      ).filter(
        (row) => row.style.display !== "none"
      )


    // -----------------------------------------------
    // Keep at least one row
    // -----------------------------------------------

    if (rows.length === 1) {

      const destroyField =
        row.querySelector(
          'input[name*="_destroy"]'
        )

      /*
       * If this is an existing persisted account,
       * do not delete it just because it is the only
       * visible row. Clear the inputs instead only
       * for a newly-created unsaved row.
       */

      const idField =
        row.querySelector(
          'input[name*="[id]"]'
        )

      if (!idField) {

        const inputs =
          row.querySelectorAll(
            "input:not([type=hidden]), select"
          )

        inputs.forEach((input) => {
          input.value = ""
        })

      } else if (destroyField) {

        destroyField.value = "1"
        row.style.display = "none"

      }

      this.updateAccountButtons()
      this.updateAccountCount()

      return
    }


    // -----------------------------------------------
    // Existing persisted account
    // -----------------------------------------------

    const destroyField =
      row.querySelector(
        'input[name*="_destroy"]'
      )


    if (destroyField) {

      destroyField.value = "1"
      row.style.display = "none"

    } else {

      // Newly-added unsaved row
      row.remove()

    }


    this.updateAccountButtons()
    this.updateAccountCount()
  }


  // --------------------------------------------------
  // UPDATE ADD BUTTONS
  // --------------------------------------------------

  updateAccountButtons() {

    const rows =
      Array.from(
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


  // --------------------------------------------------
  // UPDATE ACCOUNT COUNT
  // --------------------------------------------------

  updateAccountCount() {

    if (!this.hasAccountCountTarget) return

    const rows =
      Array.from(
        this.accountsContainerTarget.querySelectorAll(
          ".xt-exchange-row"
        )
      ).filter(
        (row) => row.style.display !== "none"
      )


    this.accountCountTarget.textContent =
      rows.length
  }
}