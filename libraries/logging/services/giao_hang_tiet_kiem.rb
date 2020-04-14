# frozen_string_literal: true

module Logging
  class GiaoHangTietKiem < ApplicationLogging
    class << self
      private

      def log_name
        'GHTK'
      end

      def logger_file_name
        logging_config.dig('giaohangtietkiem', 'file_name') || super
      end

      def logger_level
        logging_config.dig('giaohangtietkiem', 'level') || super
      end

      def display_io?
        false
      end
    end
  end
end
