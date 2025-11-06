# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

require 'dotenv/load'
require 'base64'

# Application configuration loader; handles environment variables, .env parsing, and key handling.
class AppConfig
    attr_reader :env, :port, :notification_grpc_host, :notification_bot_token, :admin_key

    # Initializes AppConfig with merged environment and .env/.dotenv values.
    #
    # Parameters:
    # - none
    #
    # Returns:
    # - AppConfig instance
    def initialize
        @env = load_env
        @port = fetch_param('RACKUP_PORT', 9292).to_i
        @notification_grpc_host = fetch_param('NOTIFICATION_GRPC_HOST', 'notification-bot:50051')
        @notification_bot_token = fetch_param('NOTIFICATION_BOT_TOKEN', nil)
        @admin_key = load_admin_key
    end

    # Checks if application debug mode is enabled via ENV.
    #
    # Parameters:
    # - none
    #
    # Returns:
    # - Boolean - true if DEBUG=true or 1
    def self.debug_mode
        env_val = ENV['DEBUG']
        env_val == 'true' || env_val == '1'
    end

    # Loads the admin key from ADMIN_KEY_PATH file.
    #
    # Parameters:
    # - none
    #
    # Returns:
    # - String (admin key, read as binary or text, stripped)
    #
    # Raises:
    # - RuntimeError if ADMIN_KEY_PATH not set in ENV or .env
    # - RuntimeError if failed to read admin key from ADMIN_KEY_PATH
    def load_admin_key
        key_path = fetch_param('PRIVATE_KEY_PATH', nil)
        raise 'PRIVATE_KEY_PATH not set in ENV or .env' unless key_path
        begin
            der = File.binread(key_path)
            Base64.strict_encode64(der)
        rescue => e
            raise "Failed to read admin private key from #{key_path}: #{e.message}"
        end
    end

    # Returns the JWT/WebApp token secret for HS256 signature of tokens used in WebApp auth.
    # Value set in WEBAPP_TOKEN_SECRET in .env/ENV, with a fallback for development.
    #
    # Returns:
    # - String: secret key for token signing/validation
    def webapp_token_secret
        fetch_param('WEBAPP_TOKEN_SECRET', 'exampledevsecret')
    end

    private

    # Loads environment variables from .env (if exists) merged with ENV.
    #
    # Parameters:
    # - none
    #
    # Returns:
    # - Hash (String=>String) - ENV union with .env
    def load_env
        env = {}
        env_path = File.expand_path('../../.env', __FILE__)
        if File.exist?(env_path)
            File.readlines(env_path).each do |line|
                next if line.strip.empty? || line.strip.start_with?('#')
                k, v = line.strip.split('=', 2)
                env[k] = v
            end
        end
        env.merge!(ENV.to_h) { |_, v1, v2| v2 }
        env
    end

    # Looks up an ENV or loaded .env parameter, with fallback default.
    #
    # Parameters:
    # - key: String - environment variable name
    # - default: any - fallback value
    #
    # Returns:
    # - String|any - found value or default
    def fetch_param(key, default)
        ENV[key] || @env[key] || default
    end
end
