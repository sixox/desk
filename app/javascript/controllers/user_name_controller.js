import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="user-name"
export default class extends Controller {
  static targets = ['name']

  connect() {
    console.log('Im connected!!')
  }
  getUserName = () => {
    const element = this.nameTarget
    const name = element.textContent
    alert(`Uclicked on, ${name}`)
  }

}
