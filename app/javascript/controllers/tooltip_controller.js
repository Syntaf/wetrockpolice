import { Controller } from "@hotwired/stimulus";
import { Tooltip } from "bootstrap";

/*
 * Bootstrap 5 tooltips are opt-in: nothing scans data-bs-toggle="tooltip"
 * automatically. Attach this controller to any element carrying tooltip
 * data attributes and a title. The title attribute stays in the markup, so
 * the text remains available even if JS never runs.
 */
export default class extends Controller {
  connect() {
    this.tooltip = new Tooltip(this.element);
  }

  disconnect() {
    this.tooltip.dispose();
  }
}
