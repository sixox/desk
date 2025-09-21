// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import * as bootstrap from "bootstrap"

window.bootstrap = bootstrap;




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
