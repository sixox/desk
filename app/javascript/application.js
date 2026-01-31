import "@hotwired/turbo-rails"
import "controllers"
import "bootstrap"
window.bootstrap = globalThis.bootstrap || window.bootstrap


import "chart.js"
window.Chart = globalThis.Chart

document.addEventListener("turbo:frame-load", function() {
  var rangeInput = document.getElementById("picked_up_range");
  var valueDisplay = document.getElementById("picked_up_value");

  if (rangeInput && valueDisplay) {
    valueDisplay.textContent = rangeInput.value;
    rangeInput.addEventListener("input", function() {
      valueDisplay.textContent = rangeInput.value;
    });
  }
});

import "trix"
import "@rails/actiontext"
