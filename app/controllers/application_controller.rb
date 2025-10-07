require 'webrick'
require_relative '../../config/initializers/app_config'
require_relative '../../lib/logger'
require_relative '../views/renderer'
require_relative 'form_handler'
require_relative '../../lib/errors'

SECTIONS = {
    '/' => 'Home',
    '/about' => 'About',
    '/portfolio' => 'Portfolio',
    '/contacts' => 'Contacts'
}

class SiteCardServlet < WEBrick::HTTPServlet::AbstractServlet
    include ErrorHandler

    def initialize(server, config, logger, renderer, form_handler)
        super(server)
        @config = config
        @logger = logger
        @renderer = renderer
        @form_handler = form_handler
    end

    def do_GET(request, response)
        with_error_handling(response, @logger) do
            section = SECTIONS[request.path] || 'Not Found'
            @logger.info("GET #{request.path} -> #{section}")
            response.status = section == 'Not Found' ? 404 : 200
            response['Content-Type'] = 'text/html; charset=utf-8'
            response.body = @renderer.render(section)
        end
    end

    def do_POST(request, response)
        with_error_handling(response, @logger) do
            if request.path == '/contacts'
                success, message = @form_handler.process_contact_form(request)
                response.status = 200
                response['Content-Type'] = 'text/html; charset=utf-8'
                response.body = "<h1>Contact Form</h1><p>#{message}</p><a href='/contacts'>Back</a>"
            else
                response.status = 404
                response.body = '<h1>404 Not Found</h1>'
            end
        end
    end
end

begin
    config = AppConfig.new
rescue ConfigError => e
    logger = AppLogger.new
    logger.error("Config initialization failed: #{e.message}")
    abort("Config initialization failed: #{e.message}")
end
logger = AppLogger.new
renderer = Renderer.new(config.content)
form_handler = FormHandler.new(logger, config)

server = WEBrick::HTTPServer.new(:Port => config.port)
servlet = proc { |*args| SiteCardServlet.new(*args, config, logger, renderer, form_handler) }
server.mount '/', servlet
server.mount '/about', servlet
server.mount '/portfolio', servlet
server.mount '/contacts', servlet

trap('INT') { server.shutdown }
logger.info("Server started on port #{config.port}")
server.start
