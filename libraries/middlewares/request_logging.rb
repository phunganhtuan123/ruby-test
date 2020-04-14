# frozen_string_literal: true

class RequestLogging
  def initialize(app)
    @app = app
  end

  def call(env)
    Logging::Request.log(env) do
      @app.call(env)
    end
  end
end
