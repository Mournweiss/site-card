require 'pg'
require_relative 'app_config'

class PGRepository
    DEFAULT_POOL_SIZE = 5
    attr_reader :pool_size

    def initialize(conn_url: nil, pool_size: DEFAULT_POOL_SIZE)
        @conn_url = conn_url || ENV['DATABASE_URL'] || _env_pg_url
        @pool_size = pool_size
        if defined?(AppConfig) && AppConfig.respond_to?(:debug_mode) && AppConfig.debug_mode
            warn "Attempting DB connect: url=#{@conn_url.gsub(/:(.+)@/, ':****@')} pool=#{@pool_size}"
        end
        begin
            @conns = Array.new(pool_size) { PG.connect(@conn_url) }
        rescue PG::Error => e
            raise BDError.new("Failed to connect to DB: #{e.message}", context: {method: 'initialize', conn_url: @conn_url, original: e})
        end
        @idx = 0
        @mutex = Mutex.new
    end

    def with_connection
        conn = nil
        begin
            @mutex.synchronize do
                @idx = (@idx + 1) % @pool_size
                conn = @conns[@idx]
            end
            yield(conn)
        rescue PG::Error => e
            raise BDError.new("PG error in with_connection: #{e.message}", context: {method: 'with_connection', original: e})
        end
    end

    def disconnect
        @conns.each { |c| c.close rescue nil }
    end

    def ping
        with_connection { |conn| conn.exec('SELECT 1') }
        true
    rescue PG::Error, StandardError
        false
    end

    private
    def _env_pg_url
        user = ENV['PGUSER'] || 'postgres'
        pass = ENV['PGPASSWORD'] ? ":#{ENV['PGPASSWORD']}" : ''
        host = ENV['PGHOST'] || 'db'
        port = ENV['PGPORT'] || '5432'
        db = ENV['PGDATABASE'] || 'sitecard'
        "postgres://#{user}#{pass}@#{host}:#{port}/#{db}"
    end
end
