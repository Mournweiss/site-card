# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

# Rack application entrypoint for SiteCard; routes requests to controllers by URL prefix.
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

# Main Rack app controller for SiteCard; dispatches request based on URL prefix.
class MainAppController

    # Initializes with all endpoint controllers.
    #
    # Parameters:
    # - auth_ctrl: AuthController
    # - admin_ctrl: AdminController
    # - public_ctrl: PublicController
    #
    # Returns:
    # - MainAppController
    def initialize(auth_ctrl, admin_ctrl, public_ctrl)
        @auth = auth_ctrl
        @admin = admin_ctrl
        @public = public_ctrl
    end

    # Main Rack entrypoint, dispatches to controllers based on path prefix.
    #
    # Parameters:
    # - env: Hash - standard Rack env
    #
    # Returns:
    # - Array [status, headers, body] as per Rack spec
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
