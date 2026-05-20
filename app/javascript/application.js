// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Flowbite — data-attribute components (dropdown, modal, drawer, accordion, tabs…)
// Init on every Turbo navigation so dynamically rendered components hook up.
import { initFlowbite } from "flowbite"
document.addEventListener("turbo:load", initFlowbite)
document.addEventListener("turbo:render", initFlowbite)
