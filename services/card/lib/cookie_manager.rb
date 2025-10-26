module CookieManager
    DEFAULTS = {
        path: "/",
        samesite: "Strict",
        http_only: true,
        secure: false,
        max_age: nil
    }.freeze

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

    def self.clear_cookie(response, key, opts = {})
        set_cookie(response, key, "", opts.merge(max_age: 0))
    end

    def self.get_cookie(request, key)
        hash = request.respond_to?(:cookies) ? request.cookies : {}
        hash[key]
    end

    def self.all_cookies(request)
        request.respond_to?(:cookies) ? request.cookies : {}
    end
end
