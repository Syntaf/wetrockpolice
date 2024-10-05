// SCSS & Icons
import "../stylesheets/application";
import "bootstrap-icons/font/bootstrap-icons.css"

// Bootstrap
import "bootstrap";
import "@popperjs/core";

// Stimulus
import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

// Rails
import Rails from "@rails/ujs"
import "@hotwired/turbo-rails";


require.context('../images', true);

const context = require.context("../controllers", true, /\.js$/);

window.Stimulus = Application.start();
Stimulus.load(definitionsFromContext(context));

Rails.start();