require 'yaml'
require 'yaml/store'

require 'celluloid'
require 'parallel'

require 'digest/sha1'
require 'oauth2'
require 'sinatra_warden'
require 'warden'

require 'open-uri'

require 'dalli'
require 'elasticsearch'
require 'rack/session/dalli'
require 'sidekiq'
require 'sidekiq/api'

require 'configurability/config'

require 'logger'
require 'http_logger'
require 'colorize'

# Only require the gems below for development environment
if $_DEV_ENV || $_TEST_ENV
  require 'awesome_print'

  require 'benchmark'
  require 'byebug'
  require 'pry'
  require 'pry-doc'

  # Force using timezone is +0700 instead of system's timezone
  ENV['TZ'] = 'Asia/Ho_Chi_Minh'
end

RequireHelper::RequireDir.config('initializers')

# RequireHelper::RequireFile.file('libraries/logging/loader')
# RequireHelper::RequireDir.libraries(recursive: false) # Require all files in libraries/*.rb
# RequireHelper::RequireDir.libraries('overrides')
# RequireHelper::RequireDir.libraries('warden')
# RequireHelper::RequireDir.libraries('middlewares')

RequireHelper::RequireFile.file('app/helpers/hlpr_init')
RequireHelper::RequireFile.file('app/models/mdl_init')
RequireHelper::RequireFile.file('app/controllers/ctrl_init')
RequireHelper::RequireFile.file('app/services/services_init')
RequireHelper::RequireFile.file('app/workers/workers_init')
