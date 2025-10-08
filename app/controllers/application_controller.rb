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

class SiteCardServlet
    include ErrorHandler

    def initialize(_server, config, logger, form_handler)
        @config = config
        @logger = logger
        @form_handler = form_handler
    end

    def do_GET(request, response)
        with_error_handling(response, @logger) do
            @logger.info("GET #{request.path} -> single-page home")
            response.status = 200
            response['Content-Type'] = 'text/html; charset=utf-8'
            response.body = [render_home]
        end
    end

    def do_POST(request, response)
        with_error_handling(response, @logger) do
            if request.path == '/contacts'
                success, message = @form_handler.process_contact_form(request)
                response.status = 200
                response['Content-Type'] = 'text/html; charset=utf-8'
                response.body = [render_home(contact_message: message)]
            else
                response.status = 404
                response.body = ['<h1>404 Not Found</h1>']
            end
        end
    end

    private

    def render_home(contact_message: nil)
        Renderer.new.render(contact_message: contact_message)
    end
end
