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

    # POST-handler for Telegram WebApp: checks admin_key and Telegram init_data,
    # calls gRPC to authorize user with notification-bot.
    #
    # Parameters:
    # - req: WEBrick::HTTPRequest (with form data)
    # - res: WEBrick::HTTPResponse
    #
    # Returns: nil
    def handle_webapp_post(req, res)
        fields = req.body.respond_to?(:read) ? URI.decode_www_form(req.body.read).to_h : {}
        admin_key = fields['admin_key']
        init_data = fields['init_data']
        begin
            tg_user = verify_webapp_init_data!(init_data)
            logger.info("Telegram WebApp user verified: #{tg_user[:user_id]}, #{tg_user[:username]}")
        rescue VerificationError => e
            logger.warn("WebApp init_data verification failed: #{e.message}")
            res.status = 401
            res.body = 'Telegram user verification failed.'
            return
        end
        unless admin_key.is_a?(String) && !admin_key.strip.empty?
            res.status = 400
            res.body = 'Admin key required.'
            return
        end
        if verify_admin_key(admin_key)
            begin
                require 'grpc'
                grpc_host = config.notification_grpc_host
                stub = Notification::NotificationDelivery::Stub.new(grpc_host, :this_channel_is_insecure)
                grpc_req = Notification::WebappUserAuthRequest.new(user_id: tg_user[:user_id], username: tg_user[:username] || "")
                grpc_resp = stub.authorize_webapp_user(grpc_req)
                if grpc_resp.success
                    logger.info("Notification-bot: user authorized via gRPC", tg_user_id: tg_user[:user_id], username: tg_user[:username])
                    res.status = 200
                    res.body = '<div class="success">WebApp authorization successful!</div>'
                else
                    logger.warn("Notification-bot: user gRPC authorization failed: #{grpc_resp.error_message}")
                    res.status = 401
                    res.body = grpc_resp.error_message || 'gRPC authorization failed.'
                end
            rescue => e
                logger.error("Notification-bot gRPC error: #{e.message}")
                res.status = 502
                res.body = 'Notification service unavailable.'
            end
        else
            logger.warn("WebApp MiniApp admin key verify failed: #{tg_user[:user_id]}")
            res.status = 401
            res.body = 'Invalid admin key.'
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
        config_key = config.admin_key || ''
        secure_compare(config_key, key)
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

    # Telegram WebApp data signature and freshness verification.
    #
    # Parameters:
    # - init_data_str: String - original Telegram WebApp init data (URL encoded)
    #
    # Returns: Hash - user info (user_id, username, full_user)
    # Raises: VerificationError if any step fails
    def verify_webapp_init_data!(init_data_str)
        token = config.notification_bot_token
        unless token
            logger.info("Verification failed: token is nil/empty")
            raise VerificationError, 'Server is misconfigured: no bot token available.'
        end
        unless init_data_str.is_a?(String) && !init_data_str.empty?
            logger.info({event: 'init_data missing or empty', got_type: init_data_str.class.name, value: init_data_str.inspect}.inspect)
            raise VerificationError, 'No init_data received'
        end
        logger.info({event: 'init_data raw', raw: init_data_str}.inspect)
        data = CGI.parse(init_data_str)
        logger.info({event: 'init_data parsed', data: data}.inspect)
        auth_date = data['auth_date']&.first
        unless auth_date
            logger.info({event: 'auth_date missing', all_keys: data.keys}.inspect)
            raise VerificationError, 'Missing auth_date'
        end
        hash = data['hash']&.first
        unless hash
            logger.info({event: 'hash missing', all_keys: data.keys}.inspect)
            raise VerificationError, 'Missing hash'
        end
        check_str = data.keys.reject { |k| k == 'hash' }.sort.map { |k| "#{k}=#{data[k].first}" }.join("\n")
        logger.info({event: 'check_str computed', check_str: check_str}.inspect)
        secret = OpenSSL::Digest::SHA256.digest(token)
        my_hash = OpenSSL::HMAC.hexdigest('SHA256', secret, check_str)
        logger.info({event: 'computed hash', my_hash: my_hash, received_hash: hash}.inspect)
        unless my_hash == hash
            logger.info({event: 'hash mismatch', my_hash: my_hash, received_hash: hash, check_str: check_str, token_last4: token[-4..-1]}.inspect)
            raise VerificationError, 'Invalid WebApp signature'
        end
        time_now = Time.now.to_i
        auth_time = auth_date.to_i
        logger.info({event: 'auth_date check', time_now: time_now, auth_date: auth_time, delta: time_now - auth_time}.inspect)
        if (time_now - auth_time).abs > 86400
            logger.info({event: 'auth_date too old', now: time_now, received: auth_time, delta: time_now - auth_time}.inspect)
            raise VerificationError, 'WebApp init_data too old'
        end
        user_json = data['user']&.first
        user = user_json ? JSON.parse(user_json) : nil
        logger.info({event: 'user parse', user_json: user_json, user: user}.inspect)
        unless user && user['id']
            logger.info({event: 'user missing', user_json: user_json, data_keys: data.keys}.inspect)
            raise VerificationError, 'Missing user data'
        end
        { user_id: user['id'].to_i, username: user['username'], full_user: user }
    end
end
