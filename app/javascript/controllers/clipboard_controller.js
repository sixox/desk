import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    console.log("Clipboard controller connected second to:", this.element);
  }

  copy(event) {
    event.preventDefault();

    const textToCopy = this.element.dataset.clipboardText;

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(textToCopy)
        .then(() => {
          console.log(`Copied to clipboard: ${textToCopy}`);
          this.element.textContent = "Copied!";
          setTimeout(() => {
            this.element.textContent = "Copy";
          }, 2000);
        })
        .catch((error) => console.error("Clipboard error:", error));
    } else {
      // Fallback for unsupported browsers
      this.fallbackCopyText(textToCopy);
    }
  }

  fallbackCopyText(text) {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.style.position = "fixed"; // Avoid scrolling to the bottom of the page
    textarea.style.opacity = "0"; // Invisible to the user
    document.body.appendChild(textarea);
    textarea.select();
    try {
      document.execCommand("copy");
      console.log(`Fallback: Copied to clipboard: ${text}`);
      this.element.textContent = "Copied!";
      setTimeout(() => {
        this.element.textContent = "Copy";
      }, 2000);
    } catch (err) {
      console.error("Fallback: Could not copy text:", err);
    }
    document.body.removeChild(textarea);
  }
}
