import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    dest: String
  }

  connect() {
    this.destinationElement = document.querySelector(this.destValue);
    this.element.addEventListener('click', this.scrollTo.bind(this));
  }

  scrollTo() {
    this.destinationElement.scrollIntoView({ behavior: "smooth" });
  }
}