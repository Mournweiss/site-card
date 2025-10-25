require 'dotenv/load'

class AppConfig
    attr_reader :env, :port

    def initialize
        @env = load_env
        @port = fetch_param('RACKUP_PORT', 9292).to_i
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
