require 'rack/request'
require 'rack/response'
require_relative './app/controllers/application_controller'
require_relative './app/controllers/form_handler'
require_relative './config/initializers/app_config'
require_relative './lib/logger'

config = AppConfig.new
logger = AppLogger.new
form_handler = FormHandler.new(logger, config)

use Rack::CommonLogger, logger.instance_variable_get(:@logger)
map '/' do
    run proc { |env|
        req = Rack::Request.new(env)
        res = Rack::Response.new
        controller = SiteCardServlet.new(nil, config, logger, form_handler)
        if req.get?
            controller.do_GET(req, res)
        elsif req.post?
            controller.do_POST(req, res)
        else
            res.status = 405
            res.write '<h1>405 Method Not Allowed</h1>'
        end
        res.finish
    }
end
