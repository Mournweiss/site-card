require 'securerandom'
require 'erb'
require_relative '../../config/initializers/app_config'
require_relative '../../lib/logger'
require_relative '../../lib/errors'
require_relative '../views/renderer'

class AdminController
    include ErrorHandler

    ADMIN_COOKIE = 'sitecard_admin'.freeze
    ADMIN_SESSION_TTL = 7200
    COOKIE_OPTIONS = {
        http_only: true,
        same_site: 'Strict',
    }.freeze

    def initialize(config, logger)
        @config = config
        @logger = logger
        @renderer = Renderer.new
        @admin_sessions = {}
    end

    def do_GET(request, response)
        if request.path =~ %r{^/admin/api/(\w+)$}
            return admin_api_get_section(Regexp.last_match(1), request, response)
        end
        case request.path
        when '/admin/'
            render_login(response, '')
        when '/admin/panel'
            if valid_admin_session?(request)
                render_panel(response)
            else
                redirect('/admin/', response)
            end
        else
            response.status = 404
            response.body = '<h1>Not Found</h1>'
        end
    end

    def do_POST(request, response)
        if request.path == '/admin/api/update'
            return admin_api_update_sections(request, response)
        end
        case request.path
        when '/admin/'
            admin_key = (request.body.respond_to?(:read) ? URI.decode_www_form(request.body.read).to_h['admin_key'] : nil)
            if !admin_key.is_a?(String) || admin_key.strip.empty?
                render_login(response, 'Key required')
                return
            end
            if verify_admin_key(admin_key)
                token = create_admin_session
                set_admin_cookie(response, token)
                @logger.info('Successful admin login')
                redirect('/admin/panel', response)
            else
                @logger.warn('Failed admin login attempt')
                render_login(response, 'Invalid key')
            end
        when '/admin/logout'
            clear_admin_cookie(response)
            @logger.info('Admin logout')
            redirect('/', response)
        else
            response.status = 404
            response.body = '<h1>Not Found</h1>'
        end
    end

    private

    def render_login(response, status_msg)
        html = load_layout('layouts/admin.html').gsub('{{status_message}}', ERB::Util.html_escape(status_msg))
        response.status = 200
        response['Content-Type'] = 'text/html; charset=utf-8'
        response.body = html
    end

    def render_panel(response)
        layout = load_layout('layouts/application.html')
        # Panel section HTML
        panel_html = load_layout('components/admin_panel.html')
        injected = layout.gsub('<main class="container py-4"></main>', "<main class=\"container py-4\">#{panel_html}</main>")
        response.status = 200
        response['Content-Type'] = 'text/html; charset=utf-8'
        response.body = injected
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
        cookie = parse_cookie(request, ADMIN_COOKIE)
        return false unless cookie && @admin_sessions[cookie]
        was_at = @admin_sessions[cookie]
        return false unless was_at && Time.now.to_i - was_at < ADMIN_SESSION_TTL
        # Extend session
        @admin_sessions[cookie] = Time.now.to_i
        true
    end

    def set_admin_cookie(response, token)
        response['Set-Cookie'] = "#{ADMIN_COOKIE}=#{token}; HttpOnly; SameSite=Strict; Path=/; Max-Age=#{ADMIN_SESSION_TTL}"
    end

    def clear_admin_cookie(response)
        response['Set-Cookie'] = "#{ADMIN_COOKIE}=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0"
    end

    def parse_cookie(request, key)
        cookies = (request.respond_to?(:cookies) ? request.cookies : nil)
        return cookies[key] if cookies&.key?(key)
        if request.header['cookie']
            request.header['cookie'][0].split(';').each do |c|
                k, v = c.strip.split('=',2)
                return v if k.strip == key
            end
        end
        nil
    end

    def redirect(url, response)
        response.status = 302
        response['Location'] = url
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
        conn = PGRepository.new
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
        conn = PGRepository.new
        arr = Experience.all(conn)
        Hash[arr.map.with_index { |e,i| ["exp#{i+1}", e.label] }]
    end
    def fetch_skills_data
        conn = PGRepository.new
        groups = SkillGroup.all(conn)
        out = {}
        groups.each_with_index do |g,i|
            out["#{g.name}"] = (Skill.all_by_group(conn, g.id) || []).map(&:name).join(', ')
        end
        out
    end
    def fetch_portfolio_data
        conn = PGRepository.new
        arr = Portfolio.all(conn)
        Hash[arr.map {|p| [p.title, p.description] }]
    end
    def fetch_contacts_data
        conn = PGRepository.new
        arr = Contact.all(conn)
        Hash[arr.map {|c| [c.label, c.value] }]
    end

    def update_section(section, value_hash)
        case section
        when 'about'
            conn = PGRepository.new
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
