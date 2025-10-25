require_relative '../config/initializers/app_config'

class SiteCardError < StandardError
    attr_reader :context
    def initialize(message = nil, context: {})
        super(message)
        @context = context || {}
    end
    def to_log
        "[#{self.class.name}] #{message} | Context: #{context}"
    end
end

class ValidationError < SiteCardError; end
class ConfigError < SiteCardError; end
class BDError < SiteCardError; end
class DataConsistencyError < SiteCardError; end
class RenderError < SiteCardError; end
class TemplateError < SiteCardError; end

module ErrorHandler
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
