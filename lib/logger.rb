require 'logger'

class AppLogger
    def initialize
        @logger = Logger.new($stdout)
        @logger.level = Logger::INFO
    end

    def info(msg); @logger.info(msg); end
    def warn(msg); @logger.warn(msg); end
    def error(msg); @logger.error(msg); end
end
