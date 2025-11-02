require 'pg'
require_relative 'app_config'

# Connection pool manager for PostgreSQL; manages DB connections and pooling for the app.
class PGRepository
    DEFAULT_POOL_SIZE = 5
    attr_reader :pool_size

    # Initializes pool with multiple PG connections.
    #
    # Parameters:
    # - conn_url: String|nil - (optional) PG URL to use (else uses ENV)
    # - pool_size: Integer - number of PG connections to hold
    #
    # Returns:
    # - PGRepository
    #
    # Raises:
    # - BDError - if initial DB connect fails
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

    # Yields a DB connection from pool, round-robin, safely among threads.
    #
    # Parameters:
    # - none (yields connection to block)
    #
    # Returns:
    # - any - value from the block
    #
    # Raises:
    # - BDError for DB errors in block
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

    # Closes all DB connections in the pool.
    #
    # Parameters:
    # - none
    #
    # Returns:
    # - nil
    def disconnect
        @conns.each { |c| c.close rescue nil }
    end

    # Pings current DB pool, returns true if available.
    #
    # Parameters:
    # - none
    #
    # Returns:
    # - Boolean - true iff ping succeeds
    def ping
        with_connection { |conn| conn.exec('SELECT 1') }
        true
    rescue PG::Error, StandardError
        false
    end

    private

    # Builds connection URL for PG from environment variables.
    #
    # Parameters:
    # - none
    #
    # Returns:
    # - String - full database URL
    def _env_pg_url
        user = ENV['PGUSER'] || 'postgres'
        pass = ENV['PGPASSWORD'] ? ":#{ENV['PGPASSWORD']}" : ''
        host = ENV['PGHOST'] || 'db'
        port = ENV['PGPORT'] || '5432'
        db = ENV['PGDATABASE'] || 'sitecard'
        "postgres://#{user}#{pass}@#{host}:#{port}/#{db}"
    end
end
