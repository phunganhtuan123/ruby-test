# frozen_string_literal: true

module Logging
  class BaolauAPI < ApplicationLogging
    class << self
      private

      def log_name
        'BAOLAU_API'
      end

      def logger_file_name
        logging_config.dig('baolau_api', 'file_name') || super
      end

      def logger_level
        logging_config.dig('baolau_api', 'level') || super
      end

      def display_io?
        false
      end
    end
  end
end
