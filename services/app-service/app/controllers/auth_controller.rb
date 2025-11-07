# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

require_relative './templates/base_controller'
require_relative '../../lib/errors'
require_relative '../../lib/cookie_manager'
require_relative '../../lib/logger'
require 'openssl'
require 'base64'
require 'cgi'
require 'json'
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

# Controller handling authentication for admin and Telegram WebApp users.
class AuthController < BaseController
    ADMIN_COOKIE = 'sitecard_admin'.freeze
    ADMIN_SESSION_TTL = 7200
    COOKIE_OPTIONS = { http_only: true, same_site: 'Strict' }.freeze

    # Handles routing for auth paths; dispatches to sub-handlers by path/verb.
    #
    # Parameters:
    # - req: WEBrick::HTTPRequest - incoming request
    # - res: WEBrick::HTTPResponse - outgoing response (mutates)
    #
    # Returns: nil
    def handle_request(req, res)
        path = req.path_info.sub(/^\/auth/, '')
        if ['', '/'].include?(path)
            do_redirect('/auth/admin', res)
        elsif path.start_with?('/admin')
            req.get? ? render_admin_auth(res) : handle_admin_post(req, res)
        elsif path.start_with?('/webapp')
            req.get? ? render_webapp_auth(res) : handle_webapp_post(req, res)
        else
            res.status = 404
            res.body = '<h1>404 Not Found</h1>'
        end
    end

    private

    # Renders the admin login form (HTML).
    #
    # Parameters:
    # - res: WEBrick::HTTPResponse - response to write HTML to
    # - msg: String (optional) - status/error message
    # - form_action: String (optional) - form action endpoint
    #
    # Returns: nil
    def render_admin_auth(res, msg = '', form_action = '/auth/admin')
        html = render_template(File.join(Renderer::COMPONENTS_PATH_AUTH, 'admin.html'),
            { login_status_msg: msg, form_action: form_action })
        res.status = 200
        res['Content-Type'] = 'text/html; charset=utf-8'
        res.body = html
    end

    # Renders the Telegram WebApp login HTML.
    #
    # Parameters:
    # - res: WEBrick::HTTPResponse
    #
    # Returns: nil
    def render_webapp_auth(res)
        html = File.read(File.join(Renderer::COMPONENTS_PATH_AUTH, 'webapp.html'))
        res.status = 200
        res['Content-Type'] = 'text/html; charset=utf-8'
        res.body = html
    end

    # POST-handler for admin login.
    #
    # Parameters:
    # - req: WEBrick::HTTPRequest (admin_key from POST)
    # - res: WEBrick::HTTPResponse
    #
    # Returns: nil
    def handle_admin_post(req, res)
        admin_key = (req.body.respond_to?(:read) ? URI.decode_www_form(req.body.read).to_h['admin_key'] : nil)
        if !admin_key.is_a?(String) || admin_key.strip.empty?
            return render_admin_auth(res, 'Admin key required.')
        end
        if verify_admin_key(admin_key)
            token = SecureRandom.hex(32)
            CookieManager.set_cookie(res, ADMIN_COOKIE, token, path: '/', max_age: ADMIN_SESSION_TTL, http_only: true, samesite: 'Strict')
            logger.info("Successful admin login")
            do_redirect('/admin', res)
        else
            logger.warn('Failed admin login attempt')
            render_admin_auth(res, 'Invalid admin key')
        end
    end

    # POST-handler for Telegram WebApp, works with euid and token.
    #
    # Parameters:
    # - req: WEBrick::HTTPRequest (with form data; params :euid, :token, ...)
    # - res: WEBrick::HTTPResponse
    #
    # Returns: nil
    def handle_webapp_post(req, res)
        fields = req.params
        euid   = fields['euid']
        token  = fields['token']
        admin_key = fields['admin_key']
        logger.info("WebApp auth received", {euid: euid&.slice(0,12), token_length: token&.length, admin_key_given: !admin_key.to_s.strip.empty?})
        unless euid && euid.length > 8 && token && token.length > 8 && admin_key && admin_key.length >= 4
            res.status = 400
            res.body = "Missing or invalid parameters (euid, token, admin_key required)."
            logger.warn("WebApp auth: Missing or invalid params", {euid_present: !euid.nil?, token_present: !token.nil?, admin_key_present: !admin_key.to_s.strip.empty?})
            return
        end
        unless verify_admin_key(admin_key)
            res.status = 401
            res.body = "Invalid admin key."
            logger.warn("WebApp admin_key invalid", {euid: euid&.slice(0,12), admin_key_length: admin_key.length})
            return
        end
        begin
            grpc_host = config.notification_grpc_host
            stub = Notification::NotificationDelivery::Stub.new(grpc_host, :this_channel_is_insecure)
            grpc_req = Notification::WebappUserAuthRequest.new(euid: euid)
            grpc_resp = stub.authorize_webapp_user(grpc_req)
            if grpc_resp.success
                logger.info("WebApp user authorized via gRPC", {euid: euid&.slice(0,12)})
                res.status = 200
                res.body = '<div class="success">Authorization successful!</div>'
            else
                logger.warn("User gRPC authorization failed: #{grpc_resp.error_message}", {euid: euid&.slice(0,12)})
                res.status = 401
                res.body = "<div class=\"auth-error\">" + CGI.escapeHTML(grpc_resp.error_message || 'gRPC authorization failed') + "</div>"
            end
        rescue => e
            logger.error("Notification-bot gRPC error: #{e.message}", {euid: euid&.slice(0,12)})
            res.status = 502
            res.body = '<div class="auth-error">Notification service unavailable</div>'
        end
    end

    # Token/uid validation logic (JWT, nonce DB, etc).
    #
    # Parameters:
    # - uid: String - user id from form/query param
    # - token: String - JWT access token (WebApp)
    #
    # Returns: Boolean - true if valid (uid/token match, signature/time ok)
    def validate_webapp_token(uid, token)
        begin
            require 'jwt'
            hmac_secret = config.webapp_token_secret
            payload, _ = JWT.decode(token, hmac_secret, true, { algorithm: 'HS256' })
            logger.debug("JWT decoded", {payload: payload, uid_param: uid})
            uid_match = payload["uid"].to_s == uid.to_s
            exp_valid = payload["exp"] && Time.at(payload["exp"]) > Time.now
            logger.debug("JWT uid_match: #{uid_match}, exp_valid: #{exp_valid}", {payload: payload, time: Time.now})
            return uid_match && exp_valid
        rescue JWT::DecodeError, JWT::ExpiredSignature => err
            logger.warn("JWT decode/expiry validation failed for uid=#{uid}", {error: err.message})
            return false
        rescue => e
            logger.error("WebApp token validation exception: #{e.message}", {uid: uid, token: token})
            return false
        end
    end

    # Redirect utility.
    #
    # Parameters:
    # - url: String - destination URL
    # - res: WEBrick::HTTPResponse
    #
    # Returns: nil
    def do_redirect(url, res)
        res.status = 302
        res['Location'] = url
        res.body = ''
    end

    # Checks validity of received admin key.
    #
    # Parameters:
    # - key: String - admin key supplied by user
    #
    # Returns: Boolean - true if matches ENV['ADMIN_KEY']
    def verify_admin_key(key)
        config_key = config.admin_key.to_s.strip.gsub(/\s+/, "")
        user_key = key.to_s.strip.gsub(/\s+/, "")
        secure_compare(config_key, user_key)
    end

    # Secure bytewise compare.
    #
    # Parameters:
    # - a: String
    # - b: String
    #
    # Returns: Boolean
    def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize
        l = a.unpack "C*"
        res = 0
        b.each_byte { |byte| res |= byte ^ l.shift }
        res == 0
    end
end
