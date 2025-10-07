class SiteCardError < StandardError; end
class ValidationError < SiteCardError; end
class ConfigError < SiteCardError; end
class RenderError < SiteCardError; end

module ErrorHandler
    def with_error_handling(response, logger)
        yield
    rescue ValidationError => e
        logger.warn("Validation error: #{e}")
        response.status = 400
        response.body = "<h1>Bad Request</h1><p>#{e}</p>"
    rescue ConfigError, RenderError => e
        logger.error("App error: #{e}")
        response.status = 500
        response.body = "<h1>Internal Server Error</h1><p>#{e}</p>"
    rescue => e
        logger.error("Unexpected error: #{e}")
        response.status = 500
        response.body = '<h1>Internal Server Error</h1>'
    end
end
