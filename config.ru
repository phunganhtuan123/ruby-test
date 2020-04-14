require './app'

# Middlewares
map('/') { run Backend::App::BookTickController }
map('/movies') { run Backend::App::PaymentController }
