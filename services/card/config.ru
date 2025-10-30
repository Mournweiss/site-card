require 'rack/request'
require 'rack/response'
require_relative './app/controllers/application_controller'
require_relative './app/controllers/admin_controller'
require_relative './config/initializers/app_config'
require_relative './lib/logger'

config = AppConfig.new
logger = AppLogger.new

site_controller = SiteCardServlet.new(nil, config, logger)
admin_controller = SiteCardAdminServlet.new(config, logger)

use Rack::CommonLogger, logger.instance_variable_get(:@logger)

map '/auth' do
    run proc { |env|
        req = Rack::Request.new(env)
        res = Rack::Response.new
        if req.get?
            admin_controller.do_GET(req, res)
        elsif req.post?
            admin_controller.do_POST(req, res)
        else
            res.status = 405
            res.write '<h1>405 Method Not Allowed</h1>'
        end
        [res.status, res.headers, [res.body.to_s]]
    }
end

map '/' do
    run proc { |env|
        req = Rack::Request.new(env)
        res = Rack::Response.new
        if req.path.start_with?('/admin')
            if req.get?
                admin_controller.do_GET(req, res)
            elsif req.post?
                admin_controller.do_POST(req, res)
            else
                res.status = 405
                res.write '<h1>405 Method Not Allowed</h1>'
            end
        else
            if req.get?
                site_controller.do_GET(req, res)
            elsif req.post?
                site_controller.do_POST(req, res)
            else
                res.status = 405
                res.write '<h1>405 Method Not Allowed</h1>'
            end
        end
        [res.status, res.headers, [res.body.to_s]]
    }
end
