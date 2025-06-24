# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "chart.js", to: "https://unpkg.com/chart.js@4.4.0/dist/chart.js"
pin "@kurkle/color", to: "https://cdn.jsdelivr.net/npm/@kurkle/color@0.3.2/dist/color.esm.js"
pin "sentiment-chart", to: "chart.js"
pin "bulk_analysis", to: "bulk_analysis.js"
pin_all_from "app/javascript", under: "javascript"
