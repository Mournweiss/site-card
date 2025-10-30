require 'rack/request'
require 'rack/response'
require_relative './app/controllers/public_controller'
require_relative './app/controllers/admin_controller'
require_relative './app/controllers/auth_controller'
require_relative './app/controllers/templates/base_controller'
require_relative './config/initializers/app_config'
require_relative './lib/logger'

config = AppConfig.new
logger = AppLogger.new

auth_controller = AuthController.new(config, logger)
admin_controller = AdminController.new(config, logger)
public_controller = PublicController.new(config, logger)

class MainAppController
    def initialize(auth_ctrl, admin_ctrl, public_ctrl)
        @auth = auth_ctrl
        @admin = admin_ctrl
        @public = public_ctrl
    end

    def call(env)
        req = Rack::Request.new(env)
        res = Rack::Response.new
        path = req.path_info
        case
        when path.start_with?('/auth')
            @auth.handle_request(req, res)
        when path.start_with?('/admin')
            @admin.handle_request(req, res)
        else
            @public.handle_request(req, res)
        end
        [res.status, res.headers, [res.body.to_s]]
    end
end

use Rack::CommonLogger, logger.instance_variable_get(:@logger)

app = MainAppController.new(auth_controller, admin_controller, public_controller)
run app
