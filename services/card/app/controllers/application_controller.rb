require 'webrick'
require_relative '../../config/initializers/app_config'
require_relative '../../lib/logger'
require_relative '../views/renderer'
require_relative '../../lib/errors'
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

class SiteCardServlet
    include ErrorHandler

    def initialize(_server, config, logger)
        @config = config
        @logger = logger
    end

    def do_GET(request, response)
        with_error_handling(response, @logger) do
            if request.path.start_with?('/public/component/')
                component = request.path.sub('/public/component/', '').gsub(/[^a-zA-Z0-9_]/, '')
                begin
                    html = RENDERER_INSTANCE.render_component(component)
                    response.status = 200
                    response['Content-Type'] = 'text/html; charset=utf-8'
                    response.body = html
                rescue => e
                    response.status = 404
                    response['Content-Type'] = 'text/plain; charset=utf-8'
                    response.body = "Component not found"
                end
            elsif request.path.start_with?('/admin')
                response.status = 405
                response.body = '<h1>405 Method Not Allowed</h1>'
            else
                @logger.info("GET #{request.path} -> single-page home")
                response.status = 200
                response['Content-Type'] = 'text/html; charset=utf-8'
                response.body = render_home
            end
        end
    end

    def do_POST(request, response)
        if request.path == "/api/message"
            begin
                payload = JSON.parse(request.body.read) rescue {}
                name = (payload["name"] || "").strip
                email = (payload["email"] || "").strip
                body = (payload["body"] || "").strip
                if name.empty? || email.empty? || body.empty?
                    return respond_json(response, { error: "All fields are required" }, 400)
                end
                unless email.match?(/^[^@\s]+@[^@\s\.]+\.[^@\.\s]+$/)
                    return respond_json(response, { error: "Invalid email format" }, 400)
                end
                grpc_host = @config.notification_grpc_host
                stub = Notification::NotificationDelivery::Stub.new(grpc_host, :this_channel_is_insecure)
                grpc_req = Notification::ContactMessageRequest.new(name: name, email: email, body: body)
                begin
                    grpc_resp = stub.deliver_contact_message(grpc_req)
                    if grpc_resp.success
                        respond_json(response, { success: true, status: "received" }, 200)
                    else
                        respond_json(response, { error: grpc_resp.error_message || "Notification delivery failed" }, 500)
                    end
                rescue StandardError => e
                    @logger.error("gRPC notify failed: #{e.class} #{e.message}")
                    respond_json(response, { error: "Notification service unavailable" }, 503)
                end
            rescue => e
                @logger.error("Contact message handling error: #{e.class} #{e.message}")
                respond_json(response, { error: "Internal error occurred" }, 500)
            end
            return
        end
        super if defined?(super)
    end

    private

    def render_home(contact_message: nil, mode: :public)
        RENDERER_INSTANCE.render(contact_message: contact_message, mode: mode)
    end

    def respond_json(response, obj, code=200)
        response.status = code
        response['Content-Type'] = 'application/json; charset=utf-8'
        response.body = JSON.generate(obj)
    end
end
