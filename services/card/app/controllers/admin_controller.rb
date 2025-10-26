require 'securerandom'
require 'erb'
require_relative '../../config/initializers/app_config'
require_relative '../../lib/logger'
require_relative '../../lib/errors'
require_relative '../views/renderer'
require_relative 'application_controller'
require_relative '../../lib/cookie_manager'

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
            case request.path
            when '/admin/auth'
                render_admin_auth(response, '')
            when '/admin'
                valid = valid_admin_session?(request)
                @logger.info("GET /admin valid_admin_session?=#{valid}")
                if valid
                    render_admin_home(response)
                else
                    redirect('/admin/auth', response)
                end
            else
                if request.path.start_with?('/admin/api/')
                    section = request.path.split('/').last
                    admin_api_get_section(section, request, response)
                    return
                end
                if request.path.start_with?('/admin/api')
                    api_json(response, {error: 'Not found'}, 404)
                    return
                end
                super if defined?(super)
            end
        end
    end

    def do_POST(request, response)
        with_error_handling(response, @logger) do
            if request.path == '/admin/auth'
                admin_key = (request.body.respond_to?(:read) ? URI.decode_www_form(request.body.read).to_h['admin_key'] : nil)
                if !admin_key.is_a?(String) || admin_key.strip.empty?
                    render_admin_auth(response, 'Admin key required.')
                    return
                end
                if verify_admin_key(admin_key)
                    token = create_admin_session
                    CookieManager.set_cookie(response, ADMIN_COOKIE, token, path: '/', max_age: ADMIN_SESSION_TTL, http_only: true, samesite: 'Strict')
                    @logger.info("Successful admin login")
                    redirect('/admin', response)
                else
                    @logger.warn('Failed admin login attempt')
                    render_admin_auth(response, 'Invalid admin key')
                end
            elsif request.path == '/admin/api/update'
                admin_api_update_sections(request, response)
            elsif request.path == '/admin/logout'
                token = CookieManager.get_cookie(request, ADMIN_COOKIE)
                clear_admin_cookie(response)
                @admin_sessions.delete(token) if @admin_sessions && token
                @logger.info("Admin logged out")
                redirect('/admin/auth', response)
            else
                if request.path.start_with?('/admin/api')
                    api_json(response, {error: 'Not found'}, 404)
                    return
                end
                super if defined?(super)
            end
        end
    end

    private

    def render_admin_auth(response, status_msg)
        path = File.join(Renderer::COMPONENTS_PATH_ADMIN, 'auth.html')
        erb_template = ERB.new(File.read(path))
        html = erb_template.result_with_hash(login_status_msg: status_msg)
        response.status = 200
        response['Content-Type'] = 'text/html; charset=utf-8'
        response.body = html
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

    def clear_admin_cookie(response)
        CookieManager.clear_cookie(response, ADMIN_COOKIE, path: '/', http_only: true, samesite: 'Strict')
    end

    def redirect(url, response)
        location = url.to_s.start_with?("/") ? url.to_s : "/"
        @logger.info("HTTP 302 Redirect Location: #{location}")
        response.status = 302
        response['Location'] = location
        response.body = ''
    end

    def load_layout(rel_path)
        pth = File.expand_path("../views/#{rel_path}", __dir__)
        File.read(pth)
    end

    def admin_api_get_section(section, request, response)
        unless valid_admin_session?(request)
            return api_json(response, {error:'Unauthorized'}, 401)
        end
        data = case section
        when 'about'
            fetch_about_data
        when 'avatar'
            fetch_avatar_data
        when 'experience'
            fetch_experience_data
        when 'skills'
            fetch_skills_data
        when 'portfolio'
            fetch_portfolio_data
        when 'contacts'
            fetch_contacts_data
        else
            return api_json(response, {error:'Unknown section'}, 400)
        end
        api_json(response, data, 200)
    rescue => e
        api_error(response, e)
    end

    def admin_api_update_sections(request, response)
        unless valid_admin_session?(request)
            return api_json(response, {error:'Unauthorized'}, 401)
        end
        body = request.body.read
        payload = JSON.parse(body) rescue nil
        return api_json(response, {error:'Bad JSON'}, 400) unless payload.is_a?(Hash)
        errs = []
        update_log = {}
        %w[about avatar experience skills portfolio contacts].each do |sec|
            next unless payload[sec].is_a?(Hash)
            begin
                update_section(sec, payload[sec])
                update_log[sec] = 'ok'
            rescue => e
                errs << {section: sec, msg: e.message}
                update_log[sec] = "error: #{e.class}"
            end
        end
        if errs.empty?
            @logger.info("Bulk update successful: #{update_log}")
            api_json(response, {result: 'ok'}, 200)
        else
            @logger.warn("Bulk update errors: #{errs}")
            api_json(response, {result: 'partial', errors: errs}, 400)
        end
    rescue => e
        api_error(response, e)
    end

    def api_json(response, obj, code=200)
        response.status = code
        response['Content-Type'] = 'application/json; charset=utf-8'
        response.body = JSON.generate(obj)
    end

    def api_error(response, err)
        if AppConfig.debug_mode
            api_json(response, {error: err.message, backtrace: err.backtrace}, 500)
        else
            api_json(response, {error:'Internal error'}, 500)
        end
    end

    def fetch_about_data
        conn = Renderer.pg_repository_instance
        about = About.fetch(conn) || OpenStruct.new
        {
            name: about.name,
            age: about.age,
            location: about.location,
            education: about.education,
            description: about.description,
            languages: about.languages
        }
    end
    def fetch_avatar_data
        fetch_about_data
    end
    def fetch_experience_data
        conn = Renderer.pg_repository_instance
        arr = Experience.all(conn)
        Hash[arr.map.with_index { |e,i| ["exp#{i+1}", e.label] }]
    end
    def fetch_skills_data
        conn = Renderer.pg_repository_instance
        groups = SkillGroup.all(conn)
        out = {}
        groups.each_with_index do |g,i|
            out["#{g.name}"] = (Skill.all_by_group(conn, g.id) || []).map(&:name).join(', ')
        end
        out
    end
    def fetch_portfolio_data
        conn = Renderer.pg_repository_instance
        arr = Portfolio.all(conn)
        Hash[arr.map {|p| [p.title, p.description] }]
    end
    def fetch_contacts_data
        conn = Renderer.pg_repository_instance
        arr = Contact.all(conn)
        Hash[arr.map {|c| [c.label, c.value] }]
    end

    def update_section(section, value_hash)
        case section
        when 'about'
            conn = Renderer.pg_repository_instance
            allowed = %w[name age location education description languages]
            safe = value_hash.select{|k,_| allowed.include?(k)}
            sets = safe.map{|k,v| "#{k}=$#{safe.keys.index(k)+1}"}
            sql = "UPDATE about SET #{sets.join(", ")} WHERE id=(SELECT id FROM about LIMIT 1)"
            conn.with_connection do |db|
                db.exec_params(sql, safe.values)
            end
            @logger.info("About updated: #{safe.keys}")
        else
            raise "Update for section #{section} is not implemented"
        end
    end
end
