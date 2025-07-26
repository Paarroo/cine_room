# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Leaflet loaded via CDN in layout
pin "chart.js", integrity: "sha384-2wXrcg/79p4j36DRuFOkfsCWesSkJlj7hun32zsN3YrslaDhBNF+kpcqkq+BKyzS" # @4.5.0
pin "@kurkle/color", to: "@kurkle--color.js", integrity: "sha384-AsDZ2ZqLsQhK0Laxet8FgS+CPUtnLf2PBcygYv6wsaawYouC2CjJtRQXnsbhZQJa" # @0.3.4
