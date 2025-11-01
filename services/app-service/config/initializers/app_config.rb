require 'dotenv/load'

class AppConfig
    attr_reader :env, :port, :notification_grpc_host, :notification_bot_token

    def initialize
        @env = load_env
        @port = fetch_param('RACKUP_PORT', 9292).to_i
        @notification_grpc_host = fetch_param('NOTIFICATION_GRPC_HOST', 'notification-bot:50051')
        @notification_bot_token = fetch_param('NOTIFICATION_BOT_TOKEN', nil)
    end

    def self.debug_mode
        env_val = ENV['DEBUG']
        env_val == 'true' || env_val == '1'
    end

    private

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

    def fetch_param(key, default)
        ENV[key] || @env[key] || default
    end
end
