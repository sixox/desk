import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["actions"]

  connect() {
    this.index = this.actionsTarget.children.length
  }

  addAction(event) {
    event.preventDefault()
    const newAction = this.element.querySelector("#action-template").innerHTML.replace(/NEW_RECORD/g, this.index)
    this.actionsTarget.insertAdjacentHTML("beforeend", newAction)
    this.index++
  }

  removeAction(event) {
    event.preventDefault()
    let actionField = event.target.closest(".nested-fields")
    actionField.querySelector("input[name*='_destroy']").value = "1"
    actionField.style.display = "none"
  }
}
