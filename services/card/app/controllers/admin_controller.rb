require_relative './templates/base_controller'
require_relative '../../lib/errors'
require_relative '../../lib/cookie_manager'
require 'securerandom'

class AdminController < BaseController
    ADMIN_COOKIE = 'sitecard_admin'.freeze
    ADMIN_SESSION_TTL = 7200
    COOKIE_OPTIONS = { http_only: true, same_site: 'Strict' }.freeze

    def handle_request(req, res)
        path = req.path_info.sub(/^\/admin/, '')
        if ['', '/'].include?(path)
            if valid_admin_session?(req)
                render_admin_home(res)
            else
                do_redirect('/auth/admin', res)
            end
        elsif path == '/logout' && req.post?
            handle_admin_logout(req, res)
        else
            res.status = 404
            res.body = '<h1>404 Not Found</h1>'
        end
    end

    private
    def render_admin_home(res)
        html = Renderer.new.render(mode: :admin)
        res.status = 200
        res['Content-Type'] = 'text/html; charset=utf-8'
        res.body = html
    end

    def handle_admin_logout(req, res)
        token = CookieManager.get_cookie(req, ADMIN_COOKIE)
        CookieManager.clear_cookie(res, ADMIN_COOKIE, path: '/', http_only: true, samesite: 'Strict')
        @admin_sessions ||= {}
        @admin_sessions.delete(token) if @admin_sessions && token
        logger.info("Admin logged out")
        do_redirect('/auth/admin', res)
    end

    def valid_admin_session?(req)
        @admin_sessions ||= {}
        token = CookieManager.get_cookie(req, ADMIN_COOKIE)
        return false unless token && @admin_sessions[token]
        was_at = @admin_sessions[token]
        return false unless was_at && Time.now.to_i - was_at < ADMIN_SESSION_TTL
        @admin_sessions[token] = Time.now.to_i
        true
    end

    def do_redirect(url, res)
        res.status = 302
        res['Location'] = url
        res.body = ''
    end
end
