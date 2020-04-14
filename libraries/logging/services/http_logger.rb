# frozen_string_literal: true

module Logging
  class HttpLogger < ApplicationLogging
    class << self
      private

      def log_name
        'HTTP'
      end

      def logger_file_name
        logging_config.dig('http_logger', 'file_name') || super
      end

      def logger_level
        logging_config.dig('http_logger', 'level') || super
      end

      def display_io?
        false
      end
    end
  end
end
