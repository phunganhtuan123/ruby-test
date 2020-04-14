# frozen_string_literal: true

module Logging
  class ApplicationLogging
    class << self
      def logger
        @logger ||= create_instance
      end

      private

      def create_instance
        log_instance = SemanticLogger::Appender::FileWithIO.new(arguments)
        log_instance.name = log_name
        log_instance
      end

      def arguments
        base = { file_name: logger_file_path, level: logger_level }
        base[:formatter] = :color if $_DEV_ENV
        base[:io] = $stderr if $_DEV_ENV && display_io?
        base
      end

      def display_io?
        $_CONFIG['logging']['display_io'] || false
      end

      def log_name
        'APP'
      end

      def logger_file_name
        $_CONFIG['logging']['file_name'] || RACK_ENV.presence || 'development'
      end

      def logger_level
        # https://rocketjob.github.io/semantic_logger/api.html
        # :trace, :debug, :info, :warn, :error, :fatal
        $_CONFIG['logging']['level'] || :error
      end

      def logging_config
        @logging_config ||= $_CONFIG['logging']
      end

      def logger_file_path
        "#{LOGS_PATH}/#{logger_file_name}"
      end
    end
  end
end
