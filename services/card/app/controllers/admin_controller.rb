require 'securerandom'
require 'erb'
require_relative '../../config/initializers/app_config'
require_relative '../../lib/logger'
require_relative '../../lib/errors'
require_relative '../views/renderer'
require_relative 'application_controller'
require_relative '../../lib/cookie_manager'
require 'openssl'
require 'base64'
require 'cgi'
require 'json'

class SiteCardAdminServlet < SiteCardServlet
    include ErrorHandler

    ADMIN_COOKIE = 'sitecard_admin'.freeze
    ADMIN_SESSION_TTL = 7200
    COOKIE_OPTIONS = {
        http_only: true,
        same_site: 'Strict',
    }.freeze

    def initialize(config, logger)
        super(nil, config, logger)
        @admin_sessions = {}
    end

    def do_GET(request, response)
        with_error_handling(response, @logger) do
            @logger.info("do_GET path=#{request.path}")
            if request.path == '/auth' || request.path == '/auth/'
                @logger.info("Redirected /auth/ to /auth/admin")
                redirect('/auth/admin', response)
            elsif request.path == '/auth/admin'
                render_admin_auth_form(response, '', '/auth/admin')
            elsif request.path == '/auth/notification'
                render_notification_auth_miniapp(response)
            elsif request.path == '/admin'
                valid = valid_admin_session?(request)
                @logger.info("GET /admin valid_admin_session?=#{valid}")
                if valid
                    render_admin_home(response)
                else
                    redirect('/auth/admin', response)
                end
            else
                super if defined?(super)
            end
        end
    end

    def do_POST(request, response)
        with_error_handling(response, @logger) do
            if request.path == '/auth/admin'
                handle_admin_login(request, response)
            elsif request.path == '/auth/notification'
                handle_notification_auth(request, response)
            elsif request.path == '/admin/logout'
                handle_admin_logout(request, response)
            else
                super if defined?(super)
            end
        end
    end

    private

    def render_admin_auth_form(response, status_msg, form_action)
        path = File.join(Renderer::COMPONENTS_PATH_PUBLIC, 'admin_auth.html')
        erb_template = ERB.new(File.read(path))
        html = erb_template.result_with_hash(login_status_msg: status_msg, form_action: form_action)
        response.status = 200
        response['Content-Type'] = 'text/html; charset=utf-8'
        response.body = html
    end

    def render_notification_auth_miniapp(response)
        path = File.join(Renderer::COMPONENTS_PATH_PUBLIC, 'notification_auth.html')
        html = File.read(path)
        response.status = 200
        response['Content-Type'] = 'text/html; charset=utf-8'
        response.body = html
    end

    def handle_admin_login(request, response)
        admin_key = (request.body.respond_to?(:read) ? URI.decode_www_form(request.body.read).to_h['admin_key'] : nil)
        if !admin_key.is_a?(String) || admin_key.strip.empty?
            render_admin_auth_form(response, 'Admin key required.', '/auth/admin')
            return
        end
        if verify_admin_key(admin_key)
            token = create_admin_session
            CookieManager.set_cookie(response, ADMIN_COOKIE, token, path: '/', max_age: ADMIN_SESSION_TTL, http_only: true, samesite: 'Strict')
            @logger.info("Successful admin login")
            redirect('/admin', response)
        else
            @logger.warn('Failed admin login attempt')
            render_admin_auth_form(response, 'Invalid admin key', '/auth/admin')
        end
    end

    def handle_admin_logout(request, response)
        token = CookieManager.get_cookie(request, ADMIN_COOKIE)
        CookieManager.clear_cookie(response, ADMIN_COOKIE, path: '/', http_only: true, samesite: 'Strict')
        @admin_sessions.delete(token) if @admin_sessions && token
        @logger.info("Admin logged out")
        redirect('/auth/admin', response)
    end

    def handle_notification_auth(request, response)
        fields = request.body.respond_to?(:read) ? URI.decode_www_form(request.body.read).to_h : {}
        admin_key = fields['admin_key']
        init_data = fields['init_data']
        begin
            tg_user = verify_notification_webapp_init_data!(init_data)
            @logger.info("Telegram WebApp user verified", tg_user_id: tg_user[:user_id], username: tg_user[:username])
        rescue VerificationError => e
            @logger.warn("Telegram init_data verification failed", error: e.message)
            response.status = 401
            response.body = 'Telegram user verification failed.'
            return
        end
        unless admin_key.is_a?(String) && !admin_key.strip.empty?
            response.status = 400
            response.body = 'Admin key required.'
            return
        end
        if verify_admin_key(admin_key)
            begin
                require 'grpc'
                grpc_host = @config.notification_grpc_host
                stub = Notification::NotificationDelivery::Stub.new(grpc_host, :this_channel_is_insecure)
                grpc_req = Notification::WebappUserAuthRequest.new(user_id: tg_user[:user_id], username: tg_user[:username] || "")
                grpc_resp = stub.authorize_webapp_user(grpc_req)
                if grpc_resp.success
                    @logger.info("Notification-bot: user authorized via gRPC", tg_user_id: tg_user[:user_id], username: tg_user[:username])
                    response.status = 200
                    response.body = '<div class="success">Notification authorization successful!</div>'
                else
                    @logger.warn("Notification-bot: user gRPC authorization failed", error: grpc_resp.error_message)
                    response.status = 401
                    response.body = grpc_resp.error_message || 'gRPC authorization failed.'
                end
            rescue => e
                @logger.error("Notification-bot gRPC error", error: e.message)
                response.status = 502
                response.body = 'Notification service unavailable.'
            end
        else
            @logger.warn('Failed notification-bot MiniApp admin key verify', tg_user_id: tg_user[:user_id])
            response.status = 401
            response.body = 'Invalid admin key.'
        end
    end

    def render_admin_home(response)
        html = render_home(mode: :admin)
        response.status = 200
        response['Content-Type'] = 'text/html; charset=utf-8'
        response.body = html
    end

    def verify_admin_key(key)
        env_key = ENV['ADMIN_KEY'] || ''
        secure_compare(env_key, key)
    end

    def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize
        l = a.unpack "C*"
        res = 0
        b.each_byte { |byte| res |= byte ^ l.shift }
        res == 0
    end

    def create_admin_session
        token = SecureRandom.hex(32)
        @admin_sessions[token] = Time.now.to_i
        token
    end

    def valid_admin_session?(request)
        token = CookieManager.get_cookie(request, ADMIN_COOKIE)
        return false unless token && @admin_sessions[token]
        was_at = @admin_sessions[token]
        return false unless was_at && Time.now.to_i - was_at < ADMIN_SESSION_TTL
        @admin_sessions[token] = Time.now.to_i
        true
    end

    def redirect(url, response)
        location = url.to_s.start_with?("/") ? url.to_s : "/"
        @logger.info("HTTP 302 Redirect Location: #{location}")
        response.status = 302
        response['Location'] = location
        response.body = ''
    end

    def verify_notification_webapp_init_data!(init_data_str)
        token = @config.notification_bot_token
        raise VerificationError, 'Server is misconfigured: no bot token available' unless token
        raise VerificationError, 'No init_data received' unless init_data_str.is_a?(String) && !init_data_str.empty?

        data = CGI.parse(init_data_str)
        auth_date = data['auth_date']&.first
        raise VerificationError, 'Missing auth_date' unless auth_date

        hash = data['hash']&.first
        raise VerificationError, 'Missing hash' unless hash

        check_str = data.keys.reject { |k| k == 'hash' }.sort.map { |k| "#{k}=#{data[k].first}" }.join("\n")
        secret = OpenSSL::Digest::SHA256.digest(token)
        my_hash = OpenSSL::HMAC.hexdigest('SHA256', secret, check_str)

        unless my_hash == hash
            raise VerificationError, 'Invalid notification WebApp signature'
        end

        if (Time.now.to_i - auth_date.to_i).abs > 86400
            raise VerificationError, 'Notification WebApp init_data too old'
        end

        user_json = data['user']&.first
        user = user_json ? JSON.parse(user_json) : nil
        raise VerificationError, 'Missing user data' unless user && user['id']
        { user_id: user['id'].to_i, username: user['username'], full_user: user }
    end
end
