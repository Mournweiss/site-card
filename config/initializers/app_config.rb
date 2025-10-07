require 'yaml'
require 'dotenv/load'

class AppConfig
    attr_reader :content, :env, :port

    def initialize
        content_path = File.expand_path('../content.yml', __dir__)
        unless File.exist?(content_path)
            raise ConfigError, "Configuration file not found: #{content_path}. Please ensure config/content.yml exists."
        end
        begin
            @content = YAML.load_file(content_path)
        rescue StandardError => e
            raise ConfigError, "Failed to load configuration file: #{content_path}. Error: #{e.message}"
        end
        @env = load_env
        @port = fetch_param('RACKUP_PORT', 9292).to_i # Now uses RACKUP_PORT
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
