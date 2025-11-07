# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

require 'logger'
require 'json'

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
    # - data: Hash (optional) - structured data
    #
    # Returns:
    # - nil
    def info(msg, data = nil)
      @logger.info(data ? "#{msg} | #{data.to_json}" : msg)
    end

    # Warn-level log message.
    #
    # Parameters:
    # - msg: String - message to log
    # - data: Hash (optional) - structured data
    #
    # Returns:
    # - nil
    def warn(msg, data = nil)
      @logger.warn(data ? "#{msg} | #{data.to_json}" : msg)
    end

    # Error-level log message.
    #
    # Parameters:
    # - msg: String - message to log
    # - data: Hash (optional) - structured data
    #
    # Returns:
    # - nil
    def error(msg, data = nil)
      @logger.error(data ? "#{msg} | #{data.to_json}" : msg)
    end

    # Debug-level log message.
    #
    # Parameters:
    # - msg: String - message to log
    # - data: Hash (optional) - structured data
    #
    # Returns:
    # - nil
    def debug(msg, data = nil)
      @logger.debug(data ? "#{msg} | #{data.to_json}" : msg)
    end
end
