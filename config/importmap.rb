# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "flowbite",   to: "flowbite.turbo.min.js" # @4.0.2 (Turbo-compatible UMD bundle, self-initializes)
pin "apexcharts", to: "apexcharts.min.js"     # @4.4.0 (UMD, sets window.ApexCharts; used by Flowbite charts)
pin "sortablejs", to: "sortable.min.js"       # @1.15.2 (UMD, sets window.Sortable; used by kanban_controller)
