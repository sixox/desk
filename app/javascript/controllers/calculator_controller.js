// app/javascript/controllers/calculator_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["unitPrice", "quantity", "totalPrice"];

  calculate = () => {
    console.log("Calculate function called!");
    const unitPrice = parseFloat(this.unitPriceTarget.value) || 0;
    const quantity = parseFloat(this.quantityTarget.value) || 0;
    console.log("Unit Price: " + unitPrice);
    console.log("Quantity: " + quantity);

    const totalPrice = unitPrice * quantity;
    console.log("Total Price: " + totalPrice);

  this.totalPriceTarget.textContent = totalPrice.toFixed(2); // Format to two decimal places
}

}
