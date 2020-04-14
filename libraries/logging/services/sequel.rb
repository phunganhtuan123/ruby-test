# frozen_string_literal: true

module Logging
  class Sequel < ApplicationLogging
    class << self
      private

      def log_name
        'SEQUEL'
      end
    end
  end
end
