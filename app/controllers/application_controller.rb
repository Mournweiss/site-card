require 'webrick'
require_relative '../../config/initializers/app_config'
require_relative '../../lib/logger'
require_relative '../views/renderer'
require_relative '../../lib/errors'

SECTIONS = {
    '/' => 'Home',
    '/about' => 'About',
    '/portfolio' => 'Portfolio',
    '/contacts' => 'Contacts'
}

class SiteCardServlet
    include ErrorHandler

    def initialize(_server, config, logger)
        @config = config
        @logger = logger
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
        response.status = 405
        response.body = ['<h1>405 Method Not Allowed</h1>']
    end

    private

    def render_home(contact_message: nil)
        Renderer.new.render(contact_message: contact_message)
    end
end
