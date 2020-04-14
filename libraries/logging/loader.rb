# frozen_string_literal: true

RequireHelper::RequireDir.libraries('logging/semantic_logger')
RequireHelper::RequireDir.libraries('logging', recursive: false)
RequireHelper::RequireDir.libraries('logging/services')

# Config HttpLogger logger
HttpLogger.logger = Logging::HttpLogger.logger

# Initialize default logger instance for system
$logger = Logging::ApplicationLogging.logger
