# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

# Utilities for setting, reading, clearing, and verifying secure cookies in Rack/WEBrick responses.
module CookieManager
    DEFAULTS = {
        path: "/",
        samesite: "Strict",
        http_only: true,
        secure: false,
        max_age: nil
    }.freeze

    # Sets a cookie on response with secure, explicit options.
    #
    # Parameters:
    # - response: WEBrick::HTTPResponse - object to set header on
    # - key: String - cookie name
    # - value: String - value (will be escaped)
    # - opts: Hash - override cookie settings (e.g., secure, max_age)
    #
    # Returns:
    # - nil
    def self.set_cookie(response, key, value, opts = {})
        options = DEFAULTS.merge(opts)
        parts = [
            "#{key}=#{Rack::Utils.escape(value)}",
            ("Path=#{options[:path]}" if options[:path]),
            ("SameSite=#{options[:samesite]}" if options[:samesite]),
            ("Max-Age=#{options[:max_age]}" if options[:max_age]),
            ("HttpOnly" if options[:http_only]),
            ("Secure" if options[:secure])
        ].compact
        response['Set-Cookie'] = parts.join('; ')
    end

    # Immediately clears a cookie by name (Max-Age=0).
    #
    # Parameters:
    # - response: WEBrick::HTTPResponse - object to clear cookie
    # - key: String - cookie name
    # - opts: Hash - override settings
    #
    # Returns:
    # - nil
    def self.clear_cookie(response, key, opts = {})
        set_cookie(response, key, "", opts.merge(max_age: 0))
    end

    # Retrieves a cookie value from request (if present).
    #
    # Parameters:
    # - request: WEBrick::HTTPRequest
    # - key: String - cookie name
    #
    # Returns:
    # - String|nil - cookie value or nil
    def self.get_cookie(request, key)
        hash = request.respond_to?(:cookies) ? request.cookies : {}
        hash[key]
    end

    # Returns all cookies (as hash) from request.
    #
    # Parameters:
    # - request: WEBrick::HTTPRequest
    #
    # Returns:
    # - Hash{String=>String}
    def self.all_cookies(request)
        request.respond_to?(:cookies) ? request.cookies : {}
    end

    # Checks consent marker ('sitecard_cookie_consent').
    #
    # Parameters:
    # - request: WEBrick::HTTPRequest
    #
    # Returns:
    # - Boolean - true if consent cookie is '1'
    def self.user_cookie_consent?(request)
        !!(get_cookie(request, 'sitecard_cookie_consent') == '1')
    end
end
