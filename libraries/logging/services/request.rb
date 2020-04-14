# frozen_string_literal: true

module Logging
  class Request < ApplicationLogging
    class << self
      def log(env)
        start_time = Time.now
        req = Rack::Request.new(env)

        logger.tagged("##{req.object_id}") do
          logger.info("Started #{req.request_method} \"#{req.fullpath}\" for #{req.ip} #{req.user_agent} at #{Time.now}".colorize(:yellow))
          logger.info('Parameters', req.params)

          status_code, headers, body = yield

          duration = start_time.distance_ms(Time.now)
          logger.info(message: request_overview_msg(status_code), duration: duration)

          [status_code, headers, body]
        end
      end

      private

      def log_name
        'REQUEST'
      end

      def request_overview_msg(status_code)
        status = http_statuses[status_code.to_s.to_sym]
        return "#{status_code} UNKNOWN\n".colorize(:red) unless status

        "Completed #{status_code} #{status[:text]}\n".colorize(status[:color])
      end

      def http_statuses
        {
          '200': {
            text: 'OK',
            color: :green
          },
          '201': {
            text: 'CREATED',
            color: :green
          },
          '301': {
            text: 'MOVED_PERMANENTLY',
            color: :blue
          },
          '302': {
            text: 'FOUND',
            color: :blue
          },
          '400': {
            text: 'BAD_REQUEST',
            color: :red
          },
          '401': {
            text: 'UNAUTHORIZED',
            color: :red
          },
          '403': {
            text: 'CUSTOM_ERROR',
            color: :red
          },
          '404': {
            text: 'NOT_FOUND',
            color: :red
          },
          '500': {
            text: 'INTERNAL_SERVER_ERROR',
            color: :red
          },
          '502': {
            text: 'BAD_GATEWAY',
            color: :red
          },
        }
      end
    end
  end
end
