require_relative './config/initializers/app_config'
require_relative './lib/logger'
require_relative './app/views/renderer'
require_relative './app/controllers/form_handler'

class App
    def initialize
        @config = AppConfig.new
        @logger = AppLogger.new
        @renderer = Renderer.new(@config.content)
        @form_handler = FormHandler.new(@logger, @config)
    end

    def call(env)
        req = Rack::Request.new(env)
        path = req.path_info.to_s
        method = req.request_method
        normalized_path = path.empty? ? '/' : path.gsub(/\/+$/, '')
        normalized_path = '/' if normalized_path.empty?
        @logger.info("Incoming request: #{method} #{normalized_path}")
        begin
            case [method, normalized_path]
            when ['GET', '/'], ['GET', '/about'], ['GET', '/portfolio'], ['GET', '/contacts']
                section = case normalized_path
                    when '/' then 'Home'
                    when '/about' then 'About'
                    when '/portfolio' then 'Portfolio'
                    when '/contacts' then 'Contacts'
                end
                body = @renderer.render(section)
                [200, { 'content-type' => 'text/html; charset=utf-8' }, [body]]
            when ['POST', '/contacts']
                begin
                    success, message = @form_handler.process_contact_form(req)
                    body = "<h1>Contact Form</h1><p>#{message}</p><a href='/contacts'>Back</a>"
                    [200, { 'content-type' => 'text/html; charset=utf-8' }, [body]]
                rescue ValidationError => e
                    [400, { 'content-type' => 'text/html; charset=utf-8' }, ["<h1>Bad Request</h1><p>#{e}</p>"]]
                end
            else
                @logger.warn("404 Not Found: #{method} #{normalized_path}")
                [404, { 'content-type' => 'text/html; charset=utf-8' }, ["<h1>404 Not Found</h1>"]]
            end
        rescue => e
            @logger.error("Internal error: #{e}")
            [500, { 'content-type' => 'text/html; charset=utf-8' }, ["<h1>Internal Server Error</h1>"]]
        end
    end
end

run App.new
