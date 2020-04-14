module Backend
  class App
    class BaseController < Sinatra::Base
      ##
      # General success handling
      def resp(status: 200, message: nil, resource: nil)
        response = {
          status: status,
          message: message,
          resource: resource
        }
        halt(status, response.to_json)
      end
    end
  end
end
