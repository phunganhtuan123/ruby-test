# frozen_string_literal: true

module Logging
  class Elasticsearch < ApplicationLogging
    class << self
      private

      def log_name
        'ES'
      end
    end
  end
end
