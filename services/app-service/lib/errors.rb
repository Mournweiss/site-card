# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

require_relative '../config/initializers/app_config'

# Defines all custom error types and an error-handling mixin for consistent API responses.
class SiteCardError < StandardError

    # Base class for all custom site errors; exposes additional context for logging/rendering.
    #
    # Parameters:
    # - message: String - human/exportable error message
    # - context: Hash - key details for debugging
    #
    # Returns:
    # - SiteCardError instance
    attr_reader :context
    def initialize(message = nil, context: {})
        super(message)
        @context = context || {}
    end

    # Turns exception and context into a loggable string.
    #
    # Returns:
    # - String - log entry
    def to_log
        "[#{self.class.name}] #{message} | Context: #{context}"
    end
end

# Raised for invalid/unsatisfied request data
class ValidationError < SiteCardError; end

# Raised for configuration loading problems
class ConfigError < SiteCardError; end

# Raised for explicit (handled) database errors
class BDError < SiteCardError; end

# Raised if something is logically inconsistent with DB or app data
class DataConsistencyError < SiteCardError; end

# Raised for template/ERB rendering problems
class RenderError < SiteCardError; end

# Raised for failures inside ERB template rendering
class TemplateError < SiteCardError; end

# Raised for cryptographic/ID signature/mismatch
class VerificationError < SiteCardError; end

# Mixin for error-handling logic used in controllers/services
module ErrorHandler

    # Wraps arbitrary block with site-style error translation logic.
    # Catches known errors, returns friendly responses; logs in debug mode.
    #
    # Parameters:
    # - response: WEBrick::HTTPResponse - writable outgoing response object
    # - logger: Logger|AppLogger - log bridge for error context
    #
    # Returns:
    # - Any (block result or nil)
    #
    # Raises:
    # - Any error not derived from handled chain
    def with_error_handling(response, logger)
        yield
    rescue ValidationError => e
        logger.warn(e.to_log) if AppConfig.debug_mode
        warn e.to_log if AppConfig.debug_mode
        response.status = 400
        response.body = "<h1>Bad Request</h1><p>#{AppConfig.debug_mode ? e.message : 'Your request was invalid. Please try again.'}</p>"
    rescue ConfigError, BDError, DataConsistencyError => e
        logger.error(e.to_log) if AppConfig.debug_mode
        warn e.to_log if AppConfig.debug_mode
        response.status = 500
        response.body = render_error_template('public/500.html', AppConfig.debug_mode ? e.message : nil)
    rescue TemplateError, RenderError => e
        logger.error(e.to_log) if AppConfig.debug_mode
        warn e.to_log if AppConfig.debug_mode
        response.status = 500
        response.body = render_error_template('public/500.html', AppConfig.debug_mode ? e.message : nil)
    rescue SiteCardError => e
        logger.error(e.to_log) if AppConfig.debug_mode
        warn e.to_log if AppConfig.debug_mode
        response.status = 500
        response.body = render_error_template('public/error.html', AppConfig.debug_mode ? e.message : nil)
    rescue => e
        log = "CRITICAL #{e.class}: #{e.message}"
        logger.error(log) if AppConfig.debug_mode
        warn log if AppConfig.debug_mode
        response.status = 500
        response.body = render_error_template('public/error.html', AppConfig.debug_mode ? 'Unexpected internal error.' : nil)
    end

    private

    # Attempts to render a given error template file, optionally injects message.
    #
    # Parameters:
    # - path: String - path to the html template (relative)
    # - err_msg: String|nil - error message to inject if debug
    #
    # Returns:
    # - String - composed error page
    def render_error_template(path, err_msg = nil)
        begin
            html = File.read(path)
            msg = AppConfig.debug_mode ? err_msg : nil
            if html =~ /<div[^>]*class=["']sitecard-error-msg["'][^>]*>.*?<\/div>/m
                html = html.gsub(/(<div[^>]*class=["']sitecard-error-msg["'][^>]*>)(.*?)(<\/div>)/m,
                    "\\1#{msg}\\3")
                return html
            end
            if html.include?("</body>") && msg
                return html.sub('</body>', "<div class='sitecard-error-msg' style='text-align:center;color:#b00;'>#{msg}</div></body>")
            end
            "<html><body><h1>Error</h1><div class='sitecard-error-msg'>#{msg}</div></body></html>"
        rescue => ex
            warn "[ErrorTemplateMissing] #{ex.class}: #{ex.message} (#{path})" if AppConfig.debug_mode
            "<html><body><h1>Error</h1><div class='sitecard-error-msg'>#{AppConfig.debug_mode ? err_msg : ''}</div></body></html>"
        end
    end
end
