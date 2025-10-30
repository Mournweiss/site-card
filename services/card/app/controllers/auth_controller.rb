require_relative './templates/base_controller'
require_relative '../../lib/errors'
require_relative '../../lib/cookie_manager'
require 'openssl'
require 'base64'
require 'cgi'
require 'json'

class AuthController < BaseController
    ADMIN_COOKIE = 'sitecard_admin'.freeze
    ADMIN_SESSION_TTL = 7200
    COOKIE_OPTIONS = { http_only: true, same_site: 'Strict' }.freeze

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
    def render_admin_auth(res, msg = '', form_action = '/auth/admin')
        html = render_template(File.join(Renderer::COMPONENTS_PATH_AUTH, 'admin.html'),
            { login_status_msg: msg, form_action: form_action })
        res.status = 200
        res['Content-Type'] = 'text/html; charset=utf-8'
        res.body = html
    end

    def render_webapp_auth(res)
        html = File.read(File.join(Renderer::COMPONENTS_PATH_AUTH, 'webapp.html'))
        res.status = 200
        res['Content-Type'] = 'text/html; charset=utf-8'
        res.body = html
    end

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

    def do_redirect(url, res)
        res.status = 302
        res['Location'] = url
        res.body = ''
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

    def verify_webapp_init_data!(init_data_str)
        token = config.notification_bot_token
        raise VerificationError, 'Server is misconfigured: no bot token available.' unless token
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
            raise VerificationError, 'Invalid WebApp signature'
        end
        if (Time.now.to_i - auth_date.to_i).abs > 86400
            raise VerificationError, 'WebApp init_data too old'
        end
        user_json = data['user']&.first
        user = user_json ? JSON.parse(user_json) : nil
        raise VerificationError, 'Missing user data' unless user && user['id']
        { user_id: user['id'].to_i, username: user['username'], full_user: user }
    end
end
