# frozen_string_literal: true

module Logging
  class DatabasePool < ApplicationLogging
    class << self
      private

      def log_name
        'SQL'
      end
    end
  end
end
