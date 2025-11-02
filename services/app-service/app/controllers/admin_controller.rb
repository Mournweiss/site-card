require_relative './templates/base_controller'
require_relative '../../lib/errors'
require_relative '../../lib/cookie_manager'
require 'securerandom'

# Handles admin area requests, authorization state, and session management.
class AdminController < BaseController
    ADMIN_COOKIE = 'sitecard_admin'.freeze  # HTTP-only cookie used to identify admin sessions
    ADMIN_SESSION_TTL = 7200                # Session time-to-live in seconds (2 hours)
    COOKIE_OPTIONS = { http_only: true, same_site: 'Strict' }.freeze

    # Main entry point for all admin requests (dispatch logic by path and verb).
    #
    # Parameters:
    # - req: WEBrick::HTTPRequest - incoming HTTP request
    # - res: WEBrick::HTTPResponse - response object for headers/body
    #
    # Returns:
    # - nil
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

    # Renders the admin dashboard HTML.
    #
    # Parameters:
    # - res: WEBrick::HTTPResponse - response to assign HTML output to
    #
    # Returns: nil
    def render_admin_home(res)
        html = Renderer.new.render(mode: :admin)
        res.status = 200
        res['Content-Type'] = 'text/html; charset=utf-8'
        res.body = html
    end

    # Performs logout: clears cookie and removes token from in-memory session hash.
    #
    # Parameters:
    # - req: WEBrick::HTTPRequest - web request object
    # - res: WEBrick::HTTPResponse - response to update
    #
    # Returns: nil
    def handle_admin_logout(req, res)
        token = CookieManager.get_cookie(req, ADMIN_COOKIE)
        # Always clear the cookie (even if session is missing)
        CookieManager.clear_cookie(res, ADMIN_COOKIE, path: '/', http_only: true, samesite: 'Strict')
        @admin_sessions ||= {}
        @admin_sessions.delete(token) if @admin_sessions && token
        logger.info("Admin logged out")
        do_redirect('/auth/admin', res)
    end

    # Checks if request is from a valid admin session.
    #
    # Parameters:
    # - req: WEBrick::HTTPRequest - request object (cookie read)
    #
    # Returns:
    # - Boolean: true if session token exists and not expired
    def valid_admin_session?(req)
        @admin_sessions ||= {}
        token = CookieManager.get_cookie(req, ADMIN_COOKIE)
        return false unless token && @admin_sessions[token]
        was_at = @admin_sessions[token]
        return false unless was_at && Time.now.to_i - was_at < ADMIN_SESSION_TTL
        @admin_sessions[token] = Time.now.to_i # update session timestamp (sliding)
        true
    end

    # Sends a 302 redirect to the specified URL.
    #
    # Parameters:
    # - url: String - redirect destination
    # - res: WEBrick::HTTPResponse - response to update
    #
    # Returns: nil
    def do_redirect(url, res)
        res.status = 302
        res['Location'] = url
        res.body = ''
    end
end
