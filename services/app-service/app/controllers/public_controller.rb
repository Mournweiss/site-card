require 'webrick'
require_relative '../../config/initializers/app_config'
require_relative '../../lib/logger'
require_relative '../views/renderer'
require_relative '../../lib/errors'
require_relative './templates/base_controller'
require 'grpc'

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

class PublicController < BaseController
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

    def render_home(res)
        html = Renderer.new.render(mode: :public)
        res.status = 200
        res['Content-Type'] = 'text/html; charset=utf-8'
        res.body = html
    end

    def respond_json(res, obj, code=200)
        res.status = code
        res['Content-Type'] = 'application/json; charset=utf-8'
        res.body = JSON.generate(obj)
    end
end
