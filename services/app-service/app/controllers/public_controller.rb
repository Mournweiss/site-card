# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

require 'webrick'
require_relative '../../config/initializers/app_config'
require_relative '../../lib/logger'
require_relative '../views/renderer'
require_relative '../../lib/errors'
require_relative './templates/base_controller'
require 'grpc'

# Add Ruby proto context for gRPC calls
PROTO_ROOT = File.expand_path('proto-context', Dir.pwd)
$LOAD_PATH.unshift(PROTO_ROOT)
begin
    require 'service_pb'
    require 'service_services_pb'
rescue LoadError => e
    STDERR.puts "Failed to load gRPC Ruby proto files: #{e.message}"
    STDERR.puts "Checked LOAD_PATH: #{$LOAD_PATH.inspect}"
    STDERR.puts "Please verify proto Ruby file generation and permissions"
    exit(2)
end

RENDERER_INSTANCE = Renderer.new

# Public-facing controller: serves components, handles contact messages, main landing.
class PublicController < BaseController

    # Routes all public (non-auth/admin) paths to handler methods.
    #
    # Parameters:
    # - req: WEBrick::HTTPRequest - incoming request
    # - res: WEBrick::HTTPResponse - outgoing response
    #
    # Returns: nil
    def handle_request(req, res)
        path = req.path_info
        if path.start_with?('/public/component/')
            handle_component(req, res)
        elsif path == '/api/message' && req.post?
            handle_message(req, res)
        else
            render_home(res)
        end
    end

    private

    # Renders a UI component fragment by name (from /public/component/<name> route).
    #
    # Parameters:
    # - req: WEBrick::HTTPRequest with path_info
    # - res: WEBrick::HTTPResponse
    #
    # Returns: nil; responds with component HTML or 404
    def handle_component(req, res)
        component = req.path_info.sub('/public/component/', '').gsub(/[^a-zA-Z0-9_]/, '')
        begin
            html = Renderer.new.render_component(component)
            res.status = 200
            res['Content-Type'] = 'text/html; charset=utf-8'
            res.body = html
        rescue => e
            res.status = 404
            res['Content-Type'] = 'text/plain; charset=utf-8'
            res.body = 'Component not found'
        end
    end

    # Handles POST to /api/message for site contact messages, sends via gRPC.
    #
    # Parameters:
    # - req: WEBrick::HTTPRequest (JSON body)
    # - res: WEBrick::HTTPResponse
    #
    # Returns: nil; responds with JSON-encoded result
    def handle_message(req, res)
        payload = JSON.parse(req.body.read) rescue {}
        name = (payload["name"] || "").strip
        email = (payload["email"] || "").strip
        body = (payload["body"] || "").strip
        if name.empty? || email.empty? || body.empty?
            return respond_json(res, { error: "All fields are required" }, 400)
        end
        unless email.match?(/^[^@\s]+@[^@\s\.]+\.[^@\.\s]+$/)
            return respond_json(res, { error: "Invalid email format" }, 400)
        end
        grpc_host = config.notification_grpc_host
        stub = Notification::NotificationDelivery::Stub.new(grpc_host, :this_channel_is_insecure)
        grpc_req = Notification::ContactMessageRequest.new(name: name, email: email, body: body)
        begin
            grpc_resp = stub.deliver_contact_message(grpc_req)
            if grpc_resp.success
                respond_json(res, { success: true, status: "received" }, 200)
            else
                respond_json(res, { error: grpc_resp.error_message || "Notification delivery failed" }, 500)
            end
        rescue StandardError => e
            logger.error("gRPC notify failed: #{e.class} #{e.message}")
            respond_json(res, { error: "Notification service unavailable" }, 503)
        end
    end

    # Renders and returns the site public landing page.
    #
    # Parameters:
    # - res: WEBrick::HTTPResponse
    #
    # Returns: nil
    def render_home(res)
        html = Renderer.new.render(mode: :public)
        res.status = 200
        res['Content-Type'] = 'text/html; charset=utf-8'
        res.body = html
    end

    # Responds with JSON body and code. Sets correct content-type.
    #
    # Parameters:
    # - res: WEBrick::HTTPResponse
    # - obj: Hash or Array to encode as JSON
    # - code: Integer (default 200) - HTTP status code
    #
    # Returns: nil
    def respond_json(res, obj, code=200)
        res.status = code
        res['Content-Type'] = 'application/json; charset=utf-8'
        res.body = JSON.generate(obj)
    end
end
