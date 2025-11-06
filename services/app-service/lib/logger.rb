# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

require 'logger'

# Facade for stdlib Logger with level & output management for app logging.
class AppLogger

    # Initializes AppLogger, sets output and default log level.
    #
    # Parameters:
    # - none
    #
    # Returns:
    # - AppLogger instance
    def initialize
        @logger = Logger.new($stdout)
        @logger.level = Logger::INFO
    end

    # Info-level log message.
    #
    # Parameters:
    # - msg: String - message to log
    #
    # Returns:
    # - nil
    def info(msg); @logger.info(msg); end

    # Warn-level log message.
    #
    # Parameters:
    # - msg: String - message to log
    #
    # Returns:
    # - nil
    def warn(msg); @logger.warn(msg); end

    # Error-level log message.
    #
    # Parameters:
    # - msg: String - message to log
    #
    # Returns:
    # - nil
    def error(msg); @logger.error(msg); end

    # Debug-level log message.
    #
    # Parameters:
    # - msg: String - message to log
    #
    # Returns:
    # - nil
    def debug(msg); @logger.debug(msg); end
end
