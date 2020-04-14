# frozen_string_literal: true

# https://raw.githubusercontent.com/rocketjob/semantic_logger/master/lib/semantic_logger/appender/file.rb
module SemanticLogger
  module Appender
    class FileWithIO < SemanticLogger::Subscriber
      def initialize(io: nil, file_name: nil, **args, &block)
        if file_name
          @io = io
          @file_name = file_name
          reopen
        elsif io
          @log = io
        else
          raise 'SemanticLogging::Appender::File missing mandatory parameter :file_name or :io'
        end

        super(**args, &block)
      end

      def reopen
        return unless @file_name

        @log = ::File.open(@file_name, ::File::WRONLY | ::File::APPEND | ::File::CREAT)
        # Force all log entries to write immediately without buffering
        # Allows multiple processes to write to the same log file simultaneously
        @log.sync = true
        @log.set_encoding(Encoding::BINARY) if @log.respond_to?(:set_encoding)
        @log
      end

      def log(log)
        @log.write(formatter.call(log, self) << "\n")
        @io&.write(formatter.call(log, self) << "\n")
        true
      end

      def flush
        @log.flush if @log.respond_to?(:flush)
      end
    end
  end
end
